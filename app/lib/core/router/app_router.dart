import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/analysis/presentation/screens/analysis_screen.dart';
import '../../features/analysis/presentation/screens/analyzing_screen.dart';
import '../../features/analysis/presentation/screens/core_claim_screen.dart';
import '../../features/analysis/presentation/screens/evidence_screen.dart';
import '../../features/analysis/presentation/screens/saved_analyses_screen.dart';
import '../../features/analysis/presentation/screens/summary_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import 'route_paths.dart';

/// App-wide router, exposed as a provider so screens can be swapped or the
/// route table extended without touching [ReasonAiApp].
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.home,
    routes: [
      GoRoute(
        path: RoutePaths.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.savedAnalyses,
        name: 'savedAnalyses',
        builder: (context, state) => const SavedAnalysesScreen(),
      ),
      GoRoute(
        path: RoutePaths.analyzing,
        name: 'analyzing',
        builder: (context, state) => const AnalyzingScreen(),
      ),
      GoRoute(
        path: RoutePaths.coreClaim,
        name: 'coreClaim',
        builder: (context, state) => const CoreClaimScreen(),
      ),
      GoRoute(
        path: RoutePaths.analysis,
        name: 'analysis',
        builder: (context, state) => const AnalysisScreen(),
      ),
      GoRoute(
        path: RoutePaths.evidence,
        name: 'evidence',
        builder: (context, state) => const EvidenceScreen(),
      ),
      GoRoute(
        path: RoutePaths.summary,
        name: 'summary',
        builder: (context, state) => const SummaryScreen(),
      ),
    ],
  );
});
