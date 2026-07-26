import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

/// Isolates the ML Kit platform channel — and the temp-file bridge it
/// needs, since its reliable input API takes a file path rather than raw
/// encoded bytes — behind a plain Dart interface. Same reasoning as
/// `OverlayBridge`/`CaptureBridge`: nothing outside this file touches
/// `google_mlkit_text_recognition` directly, and it can be faked in tests.
abstract class TextRecognizerService {
  Future<String> recognizeText(Uint8List imageBytes);
}

class MlKitTextRecognizerService implements TextRecognizerService {
  final TextRecognizer _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  @override
  Future<String> recognizeText(Uint8List imageBytes) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/reason_ai_ocr_${DateTime.now().microsecondsSinceEpoch}.png');
    await file.writeAsBytes(imageBytes);
    try {
      final result = await _recognizer.processImage(InputImage.fromFilePath(file.path));
      return result.text;
    } finally {
      if (file.existsSync()) {
        await file.delete();
      }
    }
  }

  void dispose() {
    _recognizer.close();
  }
}

final textRecognizerServiceProvider = Provider<TextRecognizerService>((ref) {
  final service = MlKitTextRecognizerService();
  ref.onDispose(service.dispose);
  return service;
});
