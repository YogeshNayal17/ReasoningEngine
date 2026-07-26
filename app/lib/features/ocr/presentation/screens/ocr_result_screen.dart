import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../capture/presentation/controllers/capture_controller.dart';
import '../controllers/ocr_controller.dart';

/// Shows the result of either capture path from the bubble menu: a selected
/// screen region (run through on-device OCR) or pasted clipboard text (shown
/// directly, no OCR needed). Reads both from `captureControllerProvider` —
/// this screen only opens once one of them is already available, since
/// selection/clipboard-read both happen before the app comes to the
/// foreground.
class OcrResultScreen extends ConsumerStatefulWidget {
  const OcrResultScreen({super.key});

  @override
  ConsumerState<OcrResultScreen> createState() => _OcrResultScreenState();
}

class _OcrResultScreenState extends ConsumerState<OcrResultScreen> {
  @override
  void initState() {
    super.initState();
    final capture = ref.read(captureControllerProvider);
    if (capture.pastedText == null && capture.capturedImage != null) {
      Future.microtask(() => ref.read(ocrControllerProvider.notifier).recognizeText(capture.capturedImage!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final capture = ref.watch(captureControllerProvider);
    final ocrState = ref.watch(ocrControllerProvider);
    final pastedText = capture.pastedText;

    return Scaffold(
      appBar: AppBar(title: const Text('Extracted text')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (pastedText == null && capture.capturedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(capture.capturedImage!, fit: BoxFit.contain),
              ),
            const SizedBox(height: 24),
            if (pastedText != null)
              SelectableText(
                pastedText.isEmpty ? '(Clipboard was empty.)' : pastedText,
                style: Theme.of(context).textTheme.bodyLarge,
              )
            else if (ocrState.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (ocrState.result case final result?)
              result.when(
                success: (text) => SelectableText(
                  text.isEmpty ? '(No text found in the selected region.)' : text,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                failure: (failure) => Text(
                  failure.message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
