import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../data/models/claim_input.dart';
import '../controllers/analysis_controller.dart';
import '../controllers/saved_analyses_controller.dart';

const _steps = [
  'Extracting claim and metadata',
  'Cross-referencing source credibility',
  'Checking for logical fallacies & emotional bias',
  'Synthesizing reasoning card',
];

const _minimumDisplay = Duration(seconds: 5);
const _stepInterval = Duration(milliseconds: 1200);

class AnalyzingScreen extends ConsumerStatefulWidget {
  const AnalyzingScreen({super.key});

  @override
  ConsumerState<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends ConsumerState<AnalyzingScreen> {
  bool _started = false;
  int _stepIndex = 0;
  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();
    _stepTimer = Timer.periodic(_stepInterval, (_) {
      if (_stepIndex < _steps.length - 1) setState(() => _stepIndex++);
    });
    Future.microtask(_run);
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    super.dispose();
  }

  Future<void> _run() async {
    if (_started) return;
    _started = true;
    await Future.wait([_doWork(), Future<void>.delayed(_minimumDisplay)]);
    if (!mounted) return;
    final result = ref.read(analysisControllerProvider).result;
    final analysis = result?.when(success: (v) => v, failure: (_) => null);
    if (analysis != null) {
      await ref.read(savedAnalysesControllerProvider.notifier).save(analysis);
      if (mounted) context.pushReplacement(RoutePaths.coreClaim);
    }
  }

  Future<void> _doWork() async {
    final claimInput = ref.read(claimInputProvider);
    if (claimInput == null) return;
    await ref.read(analysisControllerProvider.notifier).analyze(
          source: claimInput.source.apiName,
          content: claimInput.content,
        );
  }

  static String _friendlyError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('incomplete response') || lower.contains('missing:')) {
      return 'The AI couldn\'t fully analyse this content. Please try again.';
    }
    if (lower.contains('limit reached') || lower.contains('429')) {
      return raw; // daily-limit messages are already user-friendly
    }
    if (lower.contains('could not reach') || lower.contains('connection')) {
      return 'Could not reach the analysis server. Check your connection and try again.';
    }
    if (lower.contains('invalid or expired token') || lower.contains('401') || lower.contains('403')) {
      return 'Your session has expired. Please log out and log back in.';
    }
    // For any other server error hide the technical detail.
    return 'Something went wrong during analysis. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analysisState = ref.watch(analysisControllerProvider);
    final failure = analysisState.result?.when(success: (_) => null, failure: (f) => f);

    if (failure != null) {
      final userMessage = _friendlyError(failure.message);
      return Scaffold(
        appBar: AppBar(title: const Text('Veritas', style: TextStyle(fontWeight: FontWeight.w700))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Color(0xFFBA1A1A)),
                const SizedBox(height: 16),
                Text(userMessage, textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.error, fontSize: 15)),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => context.go(RoutePaths.home),
                  child: const Text('Go back'),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const AppBottomNav(activeTab: AppNavTab.home),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Veritas', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'DECONSTRUCTING CLAIM\nIN REAL-TIME',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Analyzing Information Vector',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 40),
            // Step tracker
            ...List.generate(_steps.length, (i) => _StepRow(
              index: i + 1,
              label: _steps[i],
              status: i < _stepIndex
                  ? _StepStatus.complete
                  : i == _stepIndex
                      ? _StepStatus.active
                      : _StepStatus.pending,
            )),
            const Spacer(),
            TextButton(
              onPressed: () => context.go(RoutePaths.home),
              child: Text(
                'Cancel Analysis',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(activeTab: AppNavTab.home),
    );
  }
}

enum _StepStatus { pending, active, complete }

class _StepRow extends StatelessWidget {
  const _StepRow({required this.index, required this.label, required this.status});

  final int index;
  final String label;
  final _StepStatus status;

  @override
  Widget build(BuildContext context) {
    final isLast = index == _steps.length;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column
          Column(
            children: [
              _StepIndicator(index: index, status: status),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: status == _StepStatus.complete
                        ? const Color(0xFF006A61)
                        : Colors.white.withValues(alpha: 0.15),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Label
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      color: status == _StepStatus.pending
                          ? Colors.white.withValues(alpha: 0.35)
                          : Colors.white,
                      fontSize: 14,
                      fontWeight: status == _StepStatus.active
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  if (status == _StepStatus.complete)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('Complete',
                          style: TextStyle(
                            color: const Color(0xFF86F2E4).withValues(alpha: 0.8),
                            fontSize: 11,
                          )),
                    ),
                  if (status == _StepStatus.active)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('In Progress',
                          style: TextStyle(
                            color: const Color(0xFF86F2E4),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.index, required this.status});

  final int index;
  final _StepStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      _StepStatus.complete => const SizedBox(
          width: 28,
          height: 28,
          child: CircleAvatar(
            backgroundColor: Color(0xFF006A61),
            child: Icon(Icons.check, color: Colors.white, size: 16),
          ),
        ),
      _StepStatus.active => SizedBox(
          width: 28,
          height: 28,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Color(0xFF86F2E4)),
              ),
              Text('$index',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      _StepStatus.pending => Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
          ),
          child: Center(
            child: Text('$index',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
          ),
        ),
    };
  }
}
