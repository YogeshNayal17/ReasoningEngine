import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/capture/presentation/screens/capture_crop_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/ocr/presentation/screens/ocr_result_screen.dart';
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
        path: RoutePaths.captureCrop,
        name: 'captureCrop',
        builder: (context, state) => const CaptureCropScreen(),
      ),
      GoRoute(
        path: RoutePaths.ocrResult,
        name: 'ocrResult',
        builder: (context, state) => const OcrResultScreen(),
      ),
    ],
  );
});
