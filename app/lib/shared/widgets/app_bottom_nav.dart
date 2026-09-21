import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_paths.dart';
import '../../features/analysis/presentation/controllers/analysis_controller.dart';

enum AppNavTab { home, reasoning, history }

class AppBottomNav extends ConsumerWidget {
  const AppBottomNav({super.key, required this.activeTab});

  final AppNavTab activeTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasResult = ref.watch(analysisControllerProvider).result?.when(
          success: (_) => true,
          failure: (_) => false,
        ) ??
        false;

    // Only show Reasoning tab when there's an active analysis result.
    final visibleTabs = [
      AppNavTab.home,
      if (hasResult) AppNavTab.reasoning,
      AppNavTab.history,
    ];

    // If the active tab is Reasoning but it's hidden, show Home instead.
    final effectiveTab = visibleTabs.contains(activeTab) ? activeTab : AppNavTab.home;
    final selectedIndex = visibleTabs.indexOf(effectiveTab).clamp(0, visibleTabs.length - 1);

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        switch (visibleTabs[index]) {
          case AppNavTab.home:
            context.go(RoutePaths.home);
          case AppNavTab.reasoning:
            context.go(RoutePaths.coreClaim);
          case AppNavTab.history:
            context.go(RoutePaths.savedAnalyses);
        }
      },
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        if (hasResult)
          const NavigationDestination(
            icon: Icon(Icons.psychology_outlined),
            selectedIcon: Icon(Icons.psychology),
            label: 'Reasoning',
          ),
        const NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: 'History',
        ),
      ],
    );
  }
}
