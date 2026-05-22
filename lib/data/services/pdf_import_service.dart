import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:pdfx/pdfx.dart';

import '../models/import_job.dart';
import '../models/import_result.dart';
import '../models/parsed_question.dart';
import '../models/question.dart';
import '../repositories/import_job_repository.dart';
import '../repositories/question_repository.dart';
import 'baidu_ocr_service.dart';
import 'ocr_service.dart';
import 'pdf_text_service.dart';
import 'question_classifier.dart';
import 'question_parser.dart';

class _ImportParams {
  final String filePath;
  _ImportParams(this.filePath);
}

ParseResult _parseInIsolate(_ImportParams params) {
  final bytes = File(params.filePath).readAsBytesSync();
  final pdfService = PdfTextService();
  final pages = pdfService.extractPages(bytes);
  final fullText = pages.map((p) => p.text).join('\n');
  final parser = QuestionParser();
  return parser.parse(fullText);
}

class PdfImportService {
  final ImportJobRepository _jobRepo;
  final QuestionRepository _questionRepo;
  final QuestionClassifier _classifier;
  final OcrService _ocrService;
  final BaiduOcrService _baiduOcrService;

  PdfImportService(
    this._jobRepo,
    this._questionRepo,
    this._classifier,
    this._ocrService,
    this._baiduOcrService,
  );

  Future<ImportResult> importFromPdf(
    String filePath,
    String fileName, {
    void Function(double progress, String phase)? onProgress,
    bool useCloudOcr = true,
  }) async {
    final stopwatch = Stopwatch()..start();

    final job = ImportJob(
      filePath: filePath,
      fileName: fileName,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    final jobId = await _jobRepo.insertJob(job.copyWith(status: 'parsing'));

    try {
      onProgress?.call(0.05, '正在解析PDF...');

      ParseResult parseResult;
      bool isOcr = false;

      // 尝试文本提取
      try {
        parseResult = await Isolate.run(() => _parseInIsolate(_ImportParams(filePath)));

        // 如果提取的文本太少，可能是扫描版PDF
        if (parseResult.questions.isEmpty) {
          throw Exception('未解析到题目');
        }
      } catch (e) {
        // 使用OCR识别
        isOcr = true;

        if (useCloudOcr) {
          // 使用百度云OCR
          onProgress?.call(0.05, '检测到扫描版PDF，正在使用云端OCR识别...');
          parseResult = await _parseWithCloudOcr(filePath, onProgress);
        } else {
          // 使用本地OCR
          onProgress?.call(0.05, '检测到扫描版PDF，正在本地OCR识别...');
          parseResult = await _parseWithOcr(filePath, onProgress);
        }
      }

      final allParsed = parseResult.questions;
      final examSource = parseResult.examSource;

      await _jobRepo.updateJob(job.copyWith(
        id: jobId,
        status: 'importing',
        totalQuestions: allParsed.length,
        parsedJson: jsonEncode(allParsed.map((q) => q.toJson()).toList()),
        examSource: examSource,
      ));

      onProgress?.call(0.3, '正在分类与去重...');

      final failedQuestions = allParsed.where((q) => q.hasError).toList();
      final validQuestions = allParsed.where((q) => !q.hasError).toList();

      final dedupCache = await _buildDedupCache();

      int imported = 0;
      int duplicates = 0;
      final unclassifiedQuestions = <ParsedQuestion>[];
      final questionsToInsert = <Question>[];

      // 批量处理
      const batchSize = 100;
      for (int i = 0; i < validQuestions.length; i++) {
        final pq = validQuestions[i];
        final key = _dedupKey(pq.content, jsonEncode(pq.options));
        if (dedupCache.contains(key)) {
          duplicates++;
          continue;
        }
        dedupCache.add(key);

        final classification = _classifier.classify(pq.content);
        if (classification.chapter == '未分类') {
          unclassifiedQuestions.add(pq);
        }

        questionsToInsert.add(Question(
          content: pq.content,
          module: classification.module,
          chapter: classification.chapter,
          type: pq.type,
          options: jsonEncode(pq.options),
          answer: pq.answer,
          explanation: pq.explanation,
          difficulty: 3,
          knowledgePoints: '[]',
          source: 'imported',
          examSource: examSource,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ));

        // 批量插入
        if (questionsToInsert.length >= batchSize) {
          await _questionRepo.insertQuestions(questionsToInsert);
          imported += questionsToInsert.length;
          questionsToInsert.clear();
          onProgress?.call(0.3 + 0.6 * (i + 1) / validQuestions.length, '已导入$imported题...');
        }
      }

      // 插入剩余题目
      if (questionsToInsert.isNotEmpty) {
        await _questionRepo.insertQuestions(questionsToInsert);
        imported += questionsToInsert.length;
      }

      await _jobRepo.updateJob(job.copyWith(
        id: jobId,
        status: 'completed',
        importedCount: imported,
        duplicateCount: duplicates,
        failedCount: failedQuestions.length,
      ));

      onProgress?.call(1.0, '导入完成');
      stopwatch.stop();

      return ImportResult(
        totalParsed: allParsed.length,
        imported: imported,
        duplicates: duplicates,
        failed: failedQuestions.length,
        failedQuestions: failedQuestions,
        unclassifiedQuestions: unclassifiedQuestions,
        duration: stopwatch.elapsed,
        isOcr: isOcr,
      );
    } catch (e) {
      await _jobRepo.updateJob(job.copyWith(id: jobId, status: 'failed'));
      rethrow;
    }
  }

  /// 使用百度云OCR解析PDF
  Future<ParseResult> _parseWithCloudOcr(
    String filePath,
    void Function(double progress, String phase)? onProgress,
  ) async {
    // 检查百度OCR额度
    if (!await _baiduOcrService.hasFreeQuota()) {
      throw Exception('今日免费OCR额度已用完，次日零点自动恢复');
    }

    final document = await PdfDocument.openFile(filePath);
    final totalPages = document.pagesCount;
    final tempDir = Directory.systemTemp;

    final allText = StringBuffer();
    int processedPages = 0;

    // 并发处理，每批3页
    const concurrency = 3;

    for (int batchStart = 0; batchStart < totalPages; batchStart += concurrency) {
      final batchEnd = (batchStart + concurrency).clamp(0, totalPages);
      final futures = <Future<void>>[];

      for (int i = batchStart; i < batchEnd; i++) {
        futures.add(_processPageWithCloudOcr(document, i + 1, tempDir).then((text) {
          if (text != null && text.isNotEmpty) {
            allText.writeln(text);
          }
          processedPages++;
          final progress = 0.05 + 0.2 * (processedPages / totalPages);
          onProgress?.call(progress, '云端OCR识别第$processedPages/$totalPages页...');
        }));
      }

      await Future.wait(futures);

      // 检查额度是否用完
      if (!await _baiduOcrService.hasFreeQuota()) {
        break;
      }
    }

    await document.close();

    // 清理临时文件
    try {
      final tempFiles = tempDir.listSync().where((f) => f.path.contains('ocr_page_'));
      for (final file in tempFiles) {
        await file.delete();
      }
    } catch (_) {}

    if (allText.isEmpty) {
      throw Exception('OCR未能识别到任何文字内容');
    }

    final parser = QuestionParser();
    return parser.parse(allText.toString());
  }

  Future<String?> _processPageWithCloudOcr(
    PdfDocument document,
    int pageNum,
    Directory tempDir,
  ) async {
    try {
      final page = await document.getPage(pageNum);
      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.png,
      );

      if (pageImage == null) {
        await page.close();
        return null;
      }

      final tempFile = File('${tempDir.path}/ocr_page_$pageNum.png');
      await tempFile.writeAsBytes(pageImage.bytes);
      await page.close();

      // 使用百度云OCR识别
      final result = await _baiduOcrService.recognizeText(tempFile.path);

      // 清理临时文件
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      if (result == null) {
        // 额度用完
        return null;
      }

      return result.join('\n');
    } catch (e) {
      return null;
    }
  }

  /// 使用本地OCR解析PDF
  Future<ParseResult> _parseWithOcr(
    String filePath,
    void Function(double progress, String phase)? onProgress,
  ) async {
    final fullText = await _ocrService.extractTextFromPdf(
      filePath,
      onProgress: (current, total) {
        final progress = 0.05 + 0.2 * (current / total);
        onProgress?.call(progress, '本地OCR识别第$current/$total页...');
      },
    );

    if (fullText.trim().isEmpty) {
      throw Exception('OCR未能识别到任何文字内容，请确认PDF是否包含可读文字');
    }

    final parser = QuestionParser();
    return parser.parse(fullText);
  }

  Future<Set<String>> _buildDedupCache() async {
    final all = await _questionRepo.getAllQuestions();
    return all.map((q) => _dedupKey(q.content, q.options)).toSet();
  }

  String _dedupKey(String content, String options) {
    return '${content.trim().replaceAll(RegExp(r'\s+'), '')}||${options.trim().replaceAll(RegExp(r'\s+'), '')}';
  }
}
