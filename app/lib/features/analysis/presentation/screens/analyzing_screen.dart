import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../capture/presentation/controllers/capture_controller.dart';
import '../../../ocr/presentation/controllers/ocr_controller.dart';
import '../controllers/analysis_controller.dart';

const _stepLabels = [
  'Extracting text',
  'Identifying claim(s)',
  'Understanding context',
  'Gathering evidence',
  'Generating insights',
];

const _minimumDisplay = Duration(seconds: 5);
const _stepInterval = Duration(milliseconds: 1000);

/// Shown from the moment a selection/paste produces text until the backend
/// responds. Runs on-device OCR first if there's an image, then calls
/// `POST /analyze`, but always stays visible for at least
/// [_minimumDisplay] — this is a deliberate, requested pacing (matching
/// the product mockup's "this usually takes 5-10 seconds" framing), not a
/// reflection of how long the mocked backend actually takes (milliseconds).
/// The five steps advance on a fixed timer for the same reason: the mocked
/// backend doesn't report intermediate stages, so there's no real signal
/// to drive them with yet — Milestone 7's real pipeline could replace this
/// timer with actual stage events without changing this screen's shape.
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
      if (_stepIndex < _stepLabels.length - 1) {
        setState(() => _stepIndex++);
      }
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

    final succeeded = ref.read(analysisControllerProvider).result?.when(
          success: (_) => true,
          failure: (_) => false,
        );
    if (succeeded ?? false) {
      context.pushReplacement(RoutePaths.coreClaim);
    }
  }

  Future<void> _doWork() async {
    final capture = ref.read(captureControllerProvider);
    var text = capture.pastedText;
    if (text == null && capture.capturedImage != null) {
      await ref.read(ocrControllerProvider.notifier).recognizeText(capture.capturedImage!);
      if (!mounted) return;
      text = ref.read(ocrControllerProvider).result?.when(success: (value) => value, failure: (_) => null);
    }
    if (!mounted || text == null) return;

    await ref.read(analysisControllerProvider.notifier).analyze(text);
  }

  @override
  Widget build(BuildContext context) {
    final ocrState = ref.watch(ocrControllerProvider);
    final analysisState = ref.watch(analysisControllerProvider);

    final failure = ocrState.result?.when(success: (_) => null, failure: (f) => f) ??
        analysisState.result?.when(success: (_) => null, failure: (f) => f);

    if (failure != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analyzing')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              failure.message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Analyzing')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 64, height: 64, child: CircularProgressIndicator(strokeWidth: 3)),
              const SizedBox(height: 16),
              Text('Analyzing…', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),
              for (var i = 0; i < _stepLabels.length; i++) _StepRow(label: _stepLabels[i], status: _statusFor(i)),
              const SizedBox(height: 16),
              Text('This usually takes a few seconds.', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  _StepStatus _statusFor(int index) {
    if (index < _stepIndex) return _StepStatus.done;
    if (index == _stepIndex) return _StepStatus.active;
    return _StepStatus.pending;
  }
}

enum _StepStatus { pending, active, done }

class _StepRow extends StatelessWidget {
  const _StepRow({required this.label, required this.status});

  final String label;
  final _StepStatus status;

  @override
  Widget build(BuildContext context) {
    final Widget icon = switch (status) {
      _StepStatus.done => const Icon(Icons.check_circle, color: Colors.green, size: 20),
      _StepStatus.active => const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
      _StepStatus.pending => Icon(Icons.circle_outlined, color: Theme.of(context).disabledColor, size: 20),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 20, height: 20, child: Center(child: icon)),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: status == _StepStatus.pending ? Theme.of(context).disabledColor : null)),
        ],
      ),
    );
  }
}
