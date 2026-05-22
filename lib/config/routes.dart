import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../ui/pages/home/home_page.dart';
import '../ui/pages/module/module_page.dart';
import '../ui/pages/practice/practice_page.dart';
import '../ui/pages/exam/exam_page.dart';
import '../ui/pages/exam/exam_result_page.dart';
import '../ui/pages/wrongbook/wrong_book_page.dart';
import '../ui/pages/knowledge_summary/knowledge_summary_page.dart';
import '../ui/pages/favorites/favorites_page.dart';
import '../ui/pages/review/review_page.dart';
import '../ui/pages/stats/stats_page.dart';
import '../ui/pages/manage/manage_page.dart';
import '../ui/pages/manage/add_question_page.dart';
import '../ui/pages/manage/pdf_import_page.dart';
import '../ui/pages/manage/edit_question_page.dart';
import '../ui/pages/manage/dedup_page.dart';
import '../ui/pages/manage/ocr_scan_page.dart';
import '../ui/pages/settings/settings_page.dart';
import '../ui/pages/countdown/countdown_page.dart';
import '../ui/pages/current_affairs/current_affairs_page.dart';
import '../ui/pages/essay/essay_grading_page.dart';
import '../ui/pages/recite/recite_review_page.dart';
import '../domain/enums/practice_mode.dart';
import '../data/models/parsed_question.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final goRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => child,
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => const NoTransitionPage(child: HomePage()),
        ),
        GoRoute(
          path: '/stats',
          pageBuilder: (context, state) => const NoTransitionPage(child: StatsPage()),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(child: SettingsPage()),
        ),
      ],
    ),
    GoRoute(
      path: '/module/:module',
      builder: (context, state) => ModulePage(module: state.pathParameters['module']!),
    ),
    GoRoute(
      path: '/practice',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return PracticePage(
          mode: extra?['mode'] as PracticeMode? ?? PracticeMode.sequential,
          module: extra?['module'] as String? ?? '公共基础知识',
          chapter: extra?['chapter'] as String?,
          questionIds: extra?['questionIds'] as List<int>?,
          questionCount: extra?['questionCount'] as int? ?? 20,
          examDuration: extra?['examDuration'] as int?,
          examSource: extra?['examSource'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/exam',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ExamPage(module: extra?['module'] as String? ?? '公共基础知识');
      },
    ),
    GoRoute(
      path: '/exam/result',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return ExamResultPage(
          totalCount: extra['totalCount'] as int,
          correctCount: extra['correctCount'] as int,
          duration: extra['duration'] as Duration,
          wrongQuestionIds: extra['wrongQuestionIds'] as List<int>,
        );
      },
    ),
    GoRoute(
      path: '/wrongbook',
      builder: (context, state) => const WrongBookPage(),
    ),
    GoRoute(
      path: '/knowledge-summary',
      builder: (context, state) => const KnowledgeSummaryPage(),
    ),
    GoRoute(
      path: '/favorites',
      builder: (context, state) => const FavoritesPage(),
    ),
    GoRoute(
      path: '/review',
      builder: (context, state) => const ReviewPage(),
    ),
    GoRoute(
      path: '/manage',
      builder: (context, state) => const ManagePage(),
    ),
    GoRoute(
      path: '/manage/add',
      builder: (context, state) => const AddQuestionPage(),
    ),
    GoRoute(
      path: '/manage/pdf-import',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return PdfImportPage(
          initialFilePath: extra?['filePath'] as String?,
          initialFileName: extra?['fileName'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/manage/edit-question',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is ParsedQuestion) {
          return EditQuestionPage(parsedQuestion: extra);
        }
        return const EditQuestionPage();
      },
    ),
    GoRoute(
      path: '/manage/dedup',
      builder: (context, state) => const DedupPage(),
    ),
    GoRoute(
      path: '/manage/ocr-scan',
      builder: (context, state) => const OcrScanPage(),
    ),
    GoRoute(
      path: '/countdown',
      builder: (context, state) => const CountdownPage(),
    ),
    GoRoute(
      path: '/current-affairs',
      builder: (context, state) => const CurrentAffairsPage(),
    ),
    GoRoute(
      path: '/essay-grading',
      builder: (context, state) => const EssayGradingPage(),
    ),
    GoRoute(
      path: '/recite-review',
      builder: (context, state) => const ReciteReviewPage(),
    ),
  ],
);
