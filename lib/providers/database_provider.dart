import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import '../data/database/database_helper.dart';
import '../data/repositories/question_repository.dart';
import '../data/repositories/wrong_record_repository.dart';
import '../data/repositories/favorite_repository.dart';
import '../data/repositories/stats_repository.dart';
import '../data/repositories/import_job_repository.dart';
import '../data/repositories/check_in_repository.dart';
import '../data/repositories/exam_countdown_repository.dart';
import '../data/repositories/current_affair_repository.dart';
import '../data/repositories/recite_wrong_repository.dart';
import '../data/services/ai_explanation_service.dart';
import '../data/services/import_export_service.dart';
import '../data/services/question_classifier.dart';
import '../data/services/pdf_import_service.dart';
import '../data/services/ocr_service.dart';
import '../data/services/dedup_service.dart';
import '../data/services/baidu_ocr_service.dart';
import '../data/services/multi_ai_service.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper(ref.watch(appDatabaseProvider));
});

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return QuestionRepository(ref.watch(appDatabaseProvider));
});

final wrongRecordRepositoryProvider = Provider<WrongRecordRepository>((ref) {
  return WrongRecordRepository(ref.watch(appDatabaseProvider));
});

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FavoriteRepository(ref.watch(appDatabaseProvider));
});

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository(ref.watch(appDatabaseProvider));
});

final aiExplanationServiceProvider = Provider<AiExplanationService>((ref) {
  return AiExplanationService();
});

final importExportServiceProvider = Provider<ImportExportService>((ref) {
  return ImportExportService(
    ref.watch(appDatabaseProvider),
    ref.watch(questionRepositoryProvider),
  );
});

final importJobRepositoryProvider = Provider<ImportJobRepository>((ref) {
  return ImportJobRepository(ref.watch(appDatabaseProvider));
});

final questionClassifierProvider = Provider<QuestionClassifier>((ref) {
  return QuestionClassifier();
});

final ocrServiceProvider = Provider<OcrService>((ref) {
  return OcrService();
});

final baiduOcrServiceProvider = Provider<BaiduOcrService>((ref) {
  return BaiduOcrService();
});

final pdfImportServiceProvider = Provider<PdfImportService>((ref) {
  return PdfImportService(
    ref.watch(importJobRepositoryProvider),
    ref.watch(questionRepositoryProvider),
    ref.watch(questionClassifierProvider),
    ref.watch(ocrServiceProvider),
    ref.watch(baiduOcrServiceProvider),
  );
});

final dedupServiceProvider = Provider<DedupService>((ref) {
  return DedupService(ref.watch(questionRepositoryProvider));
});

final checkInRepositoryProvider = Provider<CheckInRepository>((ref) {
  return CheckInRepository(ref.watch(appDatabaseProvider));
});

final examCountdownRepositoryProvider = Provider<ExamCountdownRepository>((ref) {
  return ExamCountdownRepository(ref.watch(appDatabaseProvider));
});

final currentAffairRepositoryProvider = Provider<CurrentAffairRepository>((ref) {
  return CurrentAffairRepository(ref.watch(appDatabaseProvider));
});

final multiAiServiceProvider = Provider<MultiAiService>((ref) {
  return MultiAiService();
});

final reciteWrongRepositoryProvider = Provider<ReciteWrongRepository>((ref) {
  return ReciteWrongRepository(ref.watch(appDatabaseProvider));
});

final databaseInitializedProvider = FutureProvider<bool>((ref) async {
  final helper = ref.watch(databaseHelperProvider);
  final populated = await helper.isDatabasePopulated();
  if (!populated) {
    await helper.loadBuiltinQuestions();
  }
  return true;
});
