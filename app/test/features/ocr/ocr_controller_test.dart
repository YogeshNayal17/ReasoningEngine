import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reason_ai/features/ocr/data/text_recognizer_service.dart';
import 'package:reason_ai/features/ocr/presentation/controllers/ocr_controller.dart';

class FakeTextRecognizerService implements TextRecognizerService {
  String? textToReturn = 'Hello world';
  Object? errorToThrow;

  @override
  Future<String> recognizeText(Uint8List imageBytes) async {
    if (errorToThrow != null) throw errorToThrow!;
    return textToReturn!;
  }
}

void main() {
  late FakeTextRecognizerService service;
  late ProviderContainer container;

  setUp(() {
    service = FakeTextRecognizerService();
    container = ProviderContainer(
      overrides: [textRecognizerServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
  });

  test('recognizeText stores a success result with the extracted text', () async {
    service.textToReturn = 'a claim worth checking';

    await container.read(ocrControllerProvider.notifier).recognizeText(Uint8List(0));

    final state = container.read(ocrControllerProvider);
    expect(state.isLoading, isFalse);
    expect(
      state.result!.when(success: (text) => text, failure: (_) => null),
      'a claim worth checking',
    );
  });

  test('recognizeText stores a failure result when the service throws', () async {
    service.errorToThrow = Exception('boom');

    await container.read(ocrControllerProvider.notifier).recognizeText(Uint8List(0));

    final state = container.read(ocrControllerProvider);
    expect(state.isLoading, isFalse);
    expect(
      state.result!.when(success: (_) => null, failure: (failure) => failure.message),
      isNotNull,
    );
  });
}
