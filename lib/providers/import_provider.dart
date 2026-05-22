import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/import_result.dart';
import '../data/services/network_service.dart';
import 'database_provider.dart';

enum ImportPhase { idle, parsing, importing, completed, error }

class ImportState {
  final ImportPhase phase;
  final double progress;
  final String phaseText;
  final ImportResult? result;
  final String? error;

  const ImportState({
    this.phase = ImportPhase.idle,
    this.progress = 0.0,
    this.phaseText = '',
    this.result,
    this.error,
  });

  ImportState copyWith({
    ImportPhase? phase,
    double? progress,
    String? phaseText,
    ImportResult? result,
    String? error,
  }) => ImportState(
    phase: phase ?? this.phase,
    progress: progress ?? this.progress,
    phaseText: phaseText ?? this.phaseText,
    result: result ?? this.result,
    error: error,
  );
}

class ImportNotifier extends StateNotifier<ImportState> {
  final Ref _ref;
  ImportNotifier(this._ref) : super(const ImportState());

  Future<void> importPdf(String filePath, String fileName) async {
    // 检查网络
    if (!await NetworkService.isNetworkAvailable()) {
      state = state.copyWith(
        phase: ImportPhase.error,
        error: '网络不可用，请检查网络连接后重试',
      );
      return;
    }

    state = state.copyWith(phase: ImportPhase.parsing, progress: 0.05, phaseText: '正在解析PDF...', error: null);

    try {
      final service = _ref.read(pdfImportServiceProvider);
      final result = await service.importFromPdf(
        filePath,
        fileName,
        onProgress: (progress, phase) {
          if (progress > 0.3) {
            state = state.copyWith(phase: ImportPhase.importing, progress: progress, phaseText: phase);
          } else {
            state = state.copyWith(progress: progress, phaseText: phase);
          }
        },
      );
      state = state.copyWith(phase: ImportPhase.completed, progress: 1.0, phaseText: '导入完成', result: result);
    } catch (e) {
      state = state.copyWith(phase: ImportPhase.error, error: e.toString());
    }
  }

  void reset() {
    state = const ImportState();
  }
}

final importProvider = StateNotifierProvider<ImportNotifier, ImportState>((ref) {
  return ImportNotifier(ref);
});
