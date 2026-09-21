import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/utils/result.dart';
import '../../data/text_recognizer_service.dart';

class OcrState {
  const OcrState({this.isLoading = false, this.result});

  final bool isLoading;

  /// Null until the first [OcrController.recognizeText] call completes.
  final Result<String>? result;

  OcrState copyWith({bool? isLoading, Result<String>? result}) {
    return OcrState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
    );
  }
}

/// The first real consumer of `core/utils/result.dart`'s `Result<T>` —
/// text recognition is exactly the "can fail in an expected way" case
/// that type was built for.
class OcrController extends Notifier<OcrState> {
  @override
  OcrState build() => const OcrState();

  Future<void> recognizeText(Uint8List imageBytes) async {
    state = state.copyWith(isLoading: true);
    try {
      final text = await ref.read(textRecognizerServiceProvider).recognizeText(imageBytes);
      state = OcrState(result: Result.success(text));
    } catch (error, stackTrace) {
      ref.read(appLoggerProvider).error('Text recognition failed', error: error, stackTrace: stackTrace);
      state = const OcrState(result: Result.failure(UnexpectedFailure('Could not extract text from the image.')));
    }
  }
}

final ocrControllerProvider = NotifierProvider<OcrController, OcrState>(OcrController.new);
