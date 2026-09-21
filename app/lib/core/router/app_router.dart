import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/analysis/presentation/screens/analysis_screen.dart';
import '../../features/analysis/presentation/screens/analyzing_screen.dart';
import '../../features/analysis/presentation/screens/chat_screen.dart';
import '../../features/analysis/presentation/screens/core_claim_screen.dart';
import '../../features/analysis/presentation/screens/evidence_screen.dart';
import '../../features/analysis/presentation/screens/saved_analyses_screen.dart';
import '../../features/analysis/presentation/screens/summary_screen.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/auth/presentation/screens/pricing_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import 'route_paths.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.home,
    refreshListenable: _AuthListenable(ref),
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      // Still restoring token from storage — don't redirect yet
      if (auth.isLoading) return null;
      final isAuth = auth.isAuthenticated;
      final isAuthRoute = state.matchedLocation == RoutePaths.auth;
      if (!isAuth && !isAuthRoute) return RoutePaths.auth;
      if (isAuth && isAuthRoute) return RoutePaths.home;
      return null;
    },
    routes: [
      GoRoute(path: RoutePaths.auth, name: 'auth', builder: (_, __) => const AuthScreen()),
      GoRoute(path: RoutePaths.home, name: 'home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: RoutePaths.pricing, name: 'pricing', builder: (_, __) => const PricingScreen()),
      GoRoute(path: RoutePaths.savedAnalyses, name: 'savedAnalyses', builder: (_, __) => const SavedAnalysesScreen()),
      GoRoute(path: RoutePaths.analyzing, name: 'analyzing', builder: (_, __) => const AnalyzingScreen()),
      GoRoute(path: RoutePaths.coreClaim, name: 'coreClaim', builder: (_, __) => const CoreClaimScreen()),
      GoRoute(path: RoutePaths.analysis, name: 'analysis', builder: (_, __) => const AnalysisScreen()),
      GoRoute(path: RoutePaths.evidence, name: 'evidence', builder: (_, __) => const EvidenceScreen()),
      GoRoute(path: RoutePaths.summary, name: 'summary', builder: (_, __) => const SummaryScreen()),
      GoRoute(path: RoutePaths.chat, name: 'chat', builder: (_, __) => const ChatScreen()),
    ],
  );
});

// GoRouter needs a Listenable to know when to re-evaluate redirects.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}
