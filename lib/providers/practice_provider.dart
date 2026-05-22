import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/question.dart';
import '../domain/enums/practice_mode.dart';

class PracticeState {
  final List<Question> questions;
  final int currentIndex;
  final Map<int, String> userAnswers; // questionId -> answer
  final Map<int, bool> answerResults; // questionId -> isCorrect
  final bool showExplanation;
  final PracticeMode mode;
  final DateTime? startTime;
  final int? examDurationMinutes;
  final Set<int> bookmarkedQuestions;

  PracticeState({
    this.questions = const [],
    this.currentIndex = 0,
    this.userAnswers = const {},
    this.answerResults = const {},
    this.showExplanation = false,
    this.mode = PracticeMode.sequential,
    this.startTime,
    this.examDurationMinutes,
    this.bookmarkedQuestions = const {},
  });

  Question? get currentQuestion =>
      questions.isNotEmpty && currentIndex < questions.length
          ? questions[currentIndex]
          : null;

  bool get isAnswered =>
      currentQuestion != null && userAnswers.containsKey(currentQuestion!.id);

  bool? get isCurrentCorrect =>
      currentQuestion != null ? answerResults[currentQuestion!.id] : null;

  int get correctCount => answerResults.values.where((v) => v).length;

  int get answeredCount => userAnswers.length;

  double get accuracy =>
      answeredCount > 0 ? correctCount / answeredCount : 0.0;

  bool get isFinished => currentIndex >= questions.length;

  PracticeState copyWith({
    List<Question>? questions,
    int? currentIndex,
    Map<int, String>? userAnswers,
    Map<int, bool>? answerResults,
    bool? showExplanation,
    PracticeMode? mode,
    DateTime? startTime,
    int? examDurationMinutes,
    Set<int>? bookmarkedQuestions,
  }) {
    return PracticeState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      userAnswers: userAnswers ?? this.userAnswers,
      answerResults: answerResults ?? this.answerResults,
      showExplanation: showExplanation ?? this.showExplanation,
      mode: mode ?? this.mode,
      startTime: startTime ?? this.startTime,
      examDurationMinutes: examDurationMinutes ?? this.examDurationMinutes,
      bookmarkedQuestions: bookmarkedQuestions ?? this.bookmarkedQuestions,
    );
  }
}

class PracticeNotifier extends StateNotifier<PracticeState> {
  PracticeNotifier() : super(PracticeState());

  void startPractice(List<Question> questions, PracticeMode mode, {int? examDuration}) {
    state = PracticeState(
      questions: questions,
      mode: mode,
      startTime: DateTime.now(),
      examDurationMinutes: examDuration,
    );
  }

  void submitAnswer(String answer) {
    final question = state.currentQuestion;
    if (question == null || state.userAnswers.containsKey(question.id)) return;

    bool isCorrect = false;
    switch (question.type) {
      case 'single_choice':
      case 'true_false':
        isCorrect = answer.trim().toUpperCase() == question.answer.trim().toUpperCase();
        break;
      case 'multiple_choice':
        final userSet = answer.split(',').map((e) => e.trim().toUpperCase()).toSet();
        final correctSet = question.answer.split(',').map((e) => e.trim().toUpperCase()).toSet();
        isCorrect = userSet.length == correctSet.length && userSet.containsAll(correctSet);
        break;
      case 'fill_blank':
        isCorrect = answer.trim().toLowerCase() == question.answer.trim().toLowerCase();
        break;
      case 'essay':
        isCorrect = true; // Essay always "correct" - self-evaluation
        break;
    }

    state = state.copyWith(
      userAnswers: {...state.userAnswers, question.id!: answer},
      answerResults: {...state.answerResults, question.id!: isCorrect},
      showExplanation: true,
    );
  }

  void nextQuestion() {
    if (state.currentIndex < state.questions.length - 1) {
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        showExplanation: false,
      );
    } else {
      state = state.copyWith(currentIndex: state.questions.length);
    }
  }

  void previousQuestion() {
    if (state.currentIndex > 0) {
      state = state.copyWith(
        currentIndex: state.currentIndex - 1,
        showExplanation: state.userAnswers.containsKey(state.questions[state.currentIndex - 1].id),
      );
    }
  }

  void goToQuestion(int index) {
    if (index >= 0 && index < state.questions.length) {
      state = state.copyWith(
        currentIndex: index,
        showExplanation: state.userAnswers.containsKey(state.questions[index].id),
      );
    }
  }

  void toggleBookmark() {
    final question = state.currentQuestion;
    if (question == null) return;
    final bookmarks = Set<int>.from(state.bookmarkedQuestions);
    if (bookmarks.contains(question.id)) {
      bookmarks.remove(question.id);
    } else {
      bookmarks.add(question.id!);
    }
    state = state.copyWith(bookmarkedQuestions: bookmarks);
  }

  void setShowExplanation(bool show) {
    state = state.copyWith(showExplanation: show);
  }

  Duration getElapsedTime() {
    if (state.startTime == null) return Duration.zero;
    return DateTime.now().difference(state.startTime!);
  }

  void reset() {
    state = PracticeState();
  }
}

final practiceProvider = StateNotifierProvider<PracticeNotifier, PracticeState>((ref) {
  return PracticeNotifier();
});
