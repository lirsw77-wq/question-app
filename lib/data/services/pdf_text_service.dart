import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class ImageOnlyPdfException implements Exception {
  final String message;
  ImageOnlyPdfException([this.message = '该PDF为纯图片文件，无法解析文字内容']);
  @override
  String toString() => message;
}

class PdfPageText {
  final int pageNumber;
  final String text;
  PdfPageText(this.pageNumber, this.text);
}

class PdfTextService {
  static final RegExp _headerFooterPattern = RegExp(
    r'^(\d+|第\d+页|-\s*\d+\s*-|—\s*\d+\s*—|页\s*\d+|Page\s*\d+)$',
    caseSensitive: false,
  );

  static final RegExp _adPattern = RegExp(
    r'(扫码|关注|公众号|微信|http|www\.|\.com|\.cn|\.net|淘宝|京东|拼多多|抖音|快手)',
    caseSensitive: false,
  );

  List<PdfPageText> extractPages(Uint8List bytes) {
    final document = PdfDocument(inputBytes: bytes);
    final pages = <PdfPageText>[];
    final extractor = PdfTextExtractor(document);

    for (int i = 0; i < document.pages.count; i++) {
      final text = extractor.extractText(startPageIndex: i, endPageIndex: i);
      final cleaned = _cleanPageText(text);
      pages.add(PdfPageText(i + 1, cleaned));
    }

    document.dispose();

    final emptyPageCount = pages.where((p) => p.text.length < 20).length;
    if (pages.isNotEmpty && emptyPageCount / pages.length > 0.7) {
      throw ImageOnlyPdfException();
    }

    return pages.where((p) => p.text.trim().isNotEmpty).toList();
  }

  String _cleanPageText(String text) {
    final lines = text.split('\n');
    final cleaned = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (_headerFooterPattern.hasMatch(trimmed)) continue;
      if (_adPattern.hasMatch(trimmed)) continue;
      cleaned.add(trimmed);
    }

    return cleaned.join('\n');
  }
}
