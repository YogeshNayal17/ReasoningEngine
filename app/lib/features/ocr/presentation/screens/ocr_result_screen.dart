import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../capture/presentation/controllers/capture_controller.dart';
import '../controllers/ocr_controller.dart';

/// Runs OCR on the selected region as soon as this screen opens and shows
/// the result. Reads the image from `captureControllerProvider` — the
/// bytes are already cropped by the native selection overlay by the time
/// this screen exists, since the app only opens once the user confirms a
/// selection out there.
class OcrResultScreen extends ConsumerStatefulWidget {
  const OcrResultScreen({super.key});

  @override
  ConsumerState<OcrResultScreen> createState() => _OcrResultScreenState();
}

class _OcrResultScreenState extends ConsumerState<OcrResultScreen> {
  @override
  void initState() {
    super.initState();
    final bytes = ref.read(captureControllerProvider).capturedImage;
    if (bytes != null) {
      Future.microtask(() => ref.read(ocrControllerProvider.notifier).recognizeText(bytes));
    }
  }

  @override
  Widget build(BuildContext context) {
    final capturedImage = ref.watch(captureControllerProvider).capturedImage;
    final ocrState = ref.watch(ocrControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Extracted text')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (capturedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(capturedImage, fit: BoxFit.contain),
              ),
            const SizedBox(height: 24),
            if (ocrState.isLoading)
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
