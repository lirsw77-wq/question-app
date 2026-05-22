import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:pdfx/pdfx.dart';

class OcrService {
  /// Extract text from a PDF file using OCR (PDF → images)
  /// Note: Actual OCR is now handled by BaiduOcrService
  /// This service only handles PDF to image conversion
  Future<List<String>> convertPdfToImages(
    String filePath, {
    void Function(int currentPage, int totalPages)? onProgress,
  }) async {
    final document = await PdfDocument.openFile(filePath);
    final totalPages = document.pagesCount;
    final tempDir = await getTemporaryDirectory();
    final imagePaths = <String>[];

    for (int i = 1; i <= totalPages; i++) {
      onProgress?.call(i, totalPages);

      final page = await document.getPage(i);
      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.png,
      );

      if (pageImage != null) {
        final tempFile = File(p.join(tempDir.path, 'ocr_page_$i.png'));
        await tempFile.writeAsBytes(pageImage.bytes);
        imagePaths.add(tempFile.path);
      }

      await page.close();
    }

    await document.close();
    return imagePaths;
  }

  /// Clean up temporary image files
  Future<void> cleanupTempFiles(List<String> filePaths) async {
    for (final path in filePaths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
  }

  /// Extract text from a PDF file (legacy method for backward compatibility)
  Future<String> extractTextFromPdf(
    String filePath, {
    void Function(int currentPage, int totalPages)? onProgress,
  }) async {
    // This method is kept for backward compatibility
    // Actual OCR should use BaiduOcrService
    return '';
  }
}
