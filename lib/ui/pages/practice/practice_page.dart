import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/enums/practice_mode.dart';
import '../../../providers/practice_provider.dart';
import '../../../providers/wrong_record_provider.dart';
import '../../../providers/favorite_provider.dart';
import '../../../providers/stats_provider.dart';
import '../../../providers/database_provider.dart';
import '../../../data/models/practice_record.dart';
import 'widgets/question_card.dart';
import 'widgets/explanation_card.dart';
import 'widgets/ai_explanation_card.dart';
import 'widgets/similar_questions_sheet.dart';

class PracticePage extends ConsumerStatefulWidget {
  final PracticeMode mode;
  final String module;
  final String? chapter;
  final List<int>? questionIds;
  final int questionCount;
  final int? examDuration;
  final String? examSource;

  const PracticePage({
    super.key,
    required this.mode,
    required this.module,
    this.chapter,
    this.questionIds,
    this.questionCount = 20,
    this.examDuration,
    this.examSource,
  });

  @override
  ConsumerState<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends ConsumerState<PracticePage> {
  bool _isLoading = true;
  bool _recordSaved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadQuestions());
  }

  Future<void> _loadQuestions() async {
    final notifier = ref.read(practiceProvider.notifier);
    final repo = ref.read(questionRepositoryProvider);

    List<dynamic> questions;
    if (widget.questionIds != null && widget.questionIds!.isNotEmpty) {
      questions = await repo.getQuestionsByIds(widget.questionIds!);
    } else if (widget.mode == PracticeMode.random) {
      questions = await repo.getRandomQuestions(widget.module, widget.questionCount, chapter: widget.chapter);
      if (widget.examSource != null && widget.examSource!.isNotEmpty) {
        questions = questions.where((q) => q.examSource == widget.examSource).toList();
      }
    } else if (widget.mode == PracticeMode.wrong || widget.mode == PracticeMode.wrongOnly) {
      final wrongRepo = ref.read(wrongRecordRepositoryProvider);
      final wrongIds = await wrongRepo.getWrongQuestionIdsByModule(widget.module);
      final count = wrongIds.length > widget.questionCount ? widget.questionCount : wrongIds.length;
      questions = await repo.getQuestionsByIds(wrongIds.take(count).toList());
    } else if (widget.mode == PracticeMode.favorite) {
      final favRepo = ref.read(favoriteRepositoryProvider);
      final favIds = await favRepo.getFavoriteQuestionIds(module: widget.module);
      questions = await repo.getQuestionsByIds(favIds);
    } else if (widget.mode == PracticeMode.review) {
      final wrongRepo = ref.read(wrongRecordRepositoryProvider);
      final dueIds = await wrongRepo.getDueReviewQuestionIds();
      questions = await repo.getQuestionsByIds(dueIds);
    } else if (widget.mode == PracticeMode.newOnly) {
      final allQuestions = widget.examSource != null && widget.examSource!.isNotEmpty
          ? await repo.getFilteredQuestions(widget.module, examSource: widget.examSource)
          : await repo.getQuestionsByChapter(widget.module, widget.chapter ?? '');
      final wrongRepo = ref.read(wrongRecordRepositoryProvider);
      final wrongIds = (await wrongRepo.getWrongQuestionIdsByModule(widget.module)).toSet();
      questions = allQuestions.where((q) => !wrongIds.contains(q.id)).toList();
      if (questions.isEmpty) questions = allQuestions;
    } else {
      // Sequential mode
      if (widget.examSource != null && widget.examSource!.isNotEmpty) {
        questions = await repo.getFilteredQuestions(widget.module, examSource: widget.examSource);
      } else if (widget.chapter != null && widget.chapter!.isNotEmpty) {
        questions = await repo.getQuestionsByChapter(widget.module, widget.chapter!);
      } else {
        questions = await repo.getQuestionsByModule(widget.module);
      }
    }

    notifier.startPractice(
      questions.cast(),
      widget.mode,
      examDuration: widget.examDuration,
    );
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final practice = ref.watch(practiceProvider);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.mode.label)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (practice.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.mode.label)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('暂无题目', style: TextStyle(fontSize: 18, color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('返回'),
              ),
            ],
          ),
        ),
      );
    }

    if (practice.isFinished) {
      if (!_recordSaved) {
        _recordSaved = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _saveRecord(practice));
      }
      return _buildResultPage(context, practice, theme);
    }

    final question = practice.currentQuestion!;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.mode.label} (${practice.currentIndex + 1}/${practice.questions.length})'),
        actions: [
          if (widget.mode == PracticeMode.exam)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(child: _buildTimer(theme)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: (practice.currentIndex + 1) / practice.questions.length,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
          // Question content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question card
                  QuestionCard(
                    question: question,
                    userAnswer: practice.userAnswers[question.id],
                    isAnswered: practice.isAnswered,
                    onAnswer: (answer) {
                      ref.read(practiceProvider.notifier).submitAnswer(answer);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Explanation
                  if (practice.showExplanation) ...[
                    ExplanationCard(
                      question: question,
                      isCorrect: practice.isCurrentCorrect ?? false,
                      userAnswer: practice.userAnswers[question.id] ?? '',
                    ),
                    const SizedBox(height: 12),

                    // AI explanation button
                    AiExplanationCard(question: question),
                    const SizedBox(height: 12),

                    // Similar questions button
                    OutlinedButton.icon(
                      onPressed: () => _showSimilarQuestions(context, question),
                      icon: const Icon(Icons.swap_horiz),
                      label: const Text('举一反三'),
                    ),
                    const SizedBox(height: 12),

                    // Favorite button
                    ref.watch(isFavoriteProvider(question.id!)).when(
                      loading: () => const SizedBox(),
                      error: (_, _) => const SizedBox(),
                      data: (isFav) => OutlinedButton.icon(
                        onPressed: () async {
                          await ref.read(favoriteRepositoryProvider).toggleFavorite(question.id!);
                          ref.invalidate(isFavoriteProvider(question.id!));
                          ref.invalidate(favoriteCountProvider);
                        },
                        icon: Icon(isFav ? Icons.bookmark : Icons.bookmark_border),
                        label: Text(isFav ? '已收藏' : '收藏'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Bottom action bar
          _buildBottomBar(context, practice, theme),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, PracticeState practice, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          // Previous
          Expanded(
            child: OutlinedButton.icon(
              onPressed: practice.currentIndex > 0
                  ? () => ref.read(practiceProvider.notifier).previousQuestion()
                  : null,
              icon: const Icon(Icons.chevron_left),
              label: const Text('上一题'),
            ),
          ),
          const SizedBox(width: 8),
          // Bookmark
          IconButton(
            onPressed: () => ref.read(practiceProvider.notifier).toggleBookmark(),
            icon: Icon(
              practice.bookmarkedQuestions.contains(practice.currentQuestion?.id)
                  ? Icons.flag : Icons.flag_outlined,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          // Next
          Expanded(
            child: ElevatedButton.icon(
              onPressed: practice.isAnswered
                  ? () {
                      _handleNextQuestion(practice);
                    }
                  : null,
              icon: Icon(practice.currentIndex < practice.questions.length - 1
                  ? Icons.chevron_right : Icons.check),
              label: Text(practice.currentIndex < practice.questions.length - 1 ? '下一题' : '完成'),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNextQuestion(PracticeState practice) {
    // Record wrong/correct for non-exam modes
    if (widget.mode != PracticeMode.exam) {
      final question = practice.currentQuestion!;
      final isCorrect = practice.isCurrentCorrect ?? false;
      if (isCorrect) {
        ref.read(wrongRecordRepositoryProvider).markCorrect(question.id!);
      } else {
        ref.read(wrongRecordRepositoryProvider).addWrongRecord(question.id!);
      }
    }
    ref.read(practiceProvider.notifier).nextQuestion();
  }

  Widget _buildTimer(ThemeData theme) {
    final elapsed = ref.read(practiceProvider.notifier).getElapsedTime();
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    return Text(
      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildResultPage(BuildContext context, PracticeState practice, ThemeData theme) {
    final accuracy = (practice.accuracy * 100).toStringAsFixed(1);
    final wrongIds = practice.answerResults.entries
        .where((e) => !e.value)
        .map((e) => e.key)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('练习完成'), automaticallyImplyLeading: false),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                practice.accuracy >= 0.8 ? Icons.emoji_events : Icons.school,
                size: 80,
                color: practice.accuracy >= 0.8 ? Colors.amber : theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text('练习完成!', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _resultStat('总题数', '${practice.questions.length}', theme),
                  _resultStat('正确数', '${practice.correctCount}', theme),
                  _resultStat('正确率', '%$accuracy', theme),
                ],
              ),
              const SizedBox(height: 32),
              if (wrongIds.isNotEmpty) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/practice', extra: {
                      'mode': PracticeMode.wrong,
                      'module': widget.module,
                      'questionIds': wrongIds,
                    }),
                    icon: const Icon(Icons.refresh),
                    label: Text('练习错题 (${wrongIds.length}题)'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('返回'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultStat(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.bodyMedium),
      ],
    );
  }

  Future<void> _saveRecord(PracticeState practice) async {
    final statsRepo = ref.read(statsRepositoryProvider);
    final elapsed = ref.read(practiceProvider.notifier).getElapsedTime();
    await statsRepo.insertRecord(PracticeRecord(
      mode: widget.mode.value,
      module: widget.module,
      chapter: widget.chapter,
      totalCount: practice.questions.length,
      correctCount: practice.correctCount,
      duration: elapsed.inSeconds,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
    // Invalidate all stats providers so home page refreshes
    ref.invalidate(statsRefreshProvider);
    ref.invalidate(todayStatsProvider);
    ref.invalidate(totalPracticeCountProvider);
    ref.invalidate(consecutiveDaysProvider);
    ref.invalidate(totalCorrectCountProvider);
    ref.invalidate(learningDaysProvider);
    ref.invalidate(wrongCountProvider);
    ref.invalidate(dueReviewCountProvider);
  }

  void _showSimilarQuestions(BuildContext context, question) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SimilarQuestionsSheet(question: question),
    );
  }
}
