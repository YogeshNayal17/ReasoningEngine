import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../capture/presentation/controllers/capture_controller.dart';
import '../../../ocr/presentation/controllers/ocr_controller.dart';
import '../controllers/analysis_controller.dart';

enum _StepStatus { pending, active, done }

class _Step {
  const _Step(this.label, this.status);
  final String label;
  final _StepStatus status;
}

/// Shown from the moment a selection/paste produces text until the backend
/// responds: runs on-device OCR first if there's an image, then calls
/// `POST /analyze`. The five labeled steps mirror the product mockup's
/// "Analyzing" screen, but only "Extracting text" reflects a real signal —
/// the mocked backend doesn't report intermediate stages, so the other
/// four move together rather than faking progress we can't observe.
class AnalyzingScreen extends ConsumerStatefulWidget {
  const AnalyzingScreen({super.key});

  @override
  ConsumerState<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends ConsumerState<AnalyzingScreen> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_run);
  }

  Future<void> _run() async {
    if (_started) return;
    _started = true;

    final capture = ref.read(captureControllerProvider);
    var text = capture.pastedText;
    if (text == null && capture.capturedImage != null) {
      await ref.read(ocrControllerProvider.notifier).recognizeText(capture.capturedImage!);
      if (!mounted) return;
      text = ref.read(ocrControllerProvider).result?.when(success: (value) => value, failure: (_) => null);
    }
    if (!mounted || text == null) return;

    await ref.read(analysisControllerProvider.notifier).analyze(text);
    if (!mounted) return;

    final succeeded = ref.read(analysisControllerProvider).result?.when(
          success: (_) => true,
          failure: (_) => false,
        );
    if (succeeded ?? false) {
      context.pushReplacement(RoutePaths.analysisResult);
    }
  }

  @override
  Widget build(BuildContext context) {
    final capture = ref.watch(captureControllerProvider);
    final ocrState = ref.watch(ocrControllerProvider);
    final analysisState = ref.watch(analysisControllerProvider);

    final usingPastedText = capture.pastedText != null;
    final ocrSucceeded = ocrState.result?.when(success: (_) => true, failure: (_) => false) ?? false;
    final extractingDone = usingPastedText || ocrSucceeded;

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

    final analysisDone = analysisState.result != null;
    final laterStatus = !extractingDone
        ? _StepStatus.pending
        : (analysisDone ? _StepStatus.done : _StepStatus.active);
    final restStatus = laterStatus == _StepStatus.done ? _StepStatus.done : _StepStatus.pending;

    final steps = [
      _Step('Extracting text', extractingDone ? _StepStatus.done : _StepStatus.active),
      _Step('Identifying claim(s)', laterStatus),
      _Step('Understanding context', restStatus),
      _Step('Gathering evidence', restStatus),
      _Step('Generating insights', restStatus),
    ];

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
              for (final step in steps) _StepRow(step: step),
              const SizedBox(height: 16),
              Text('This may take a few seconds.', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});

  final _Step step;

  @override
  Widget build(BuildContext context) {
    final Widget icon = switch (step.status) {
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
          Text(
            step.label,
            style: TextStyle(color: step.status == _StepStatus.pending ? Theme.of(context).disabledColor : null),
          ),
        ],
      ),
    );
  }
}
