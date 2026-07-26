import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/analysis/presentation/screens/analysis_result_screen.dart';
import '../../features/analysis/presentation/screens/analyzing_screen.dart';
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
        path: RoutePaths.analyzing,
        name: 'analyzing',
        builder: (context, state) => const AnalyzingScreen(),
      ),
      GoRoute(
        path: RoutePaths.analysisResult,
        name: 'analysisResult',
        builder: (context, state) => const AnalysisResultScreen(),
      ),
    ],
  );
});
