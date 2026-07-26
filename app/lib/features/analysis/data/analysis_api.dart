import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_environment.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/utils/result.dart';
import 'models/analyze_result.dart';

/// Isolates the backend HTTP call behind a plain Dart interface, mirroring
/// `CaptureBridge`/`TextRecognizerService` — nothing outside this file
/// touches `package:http` directly.
abstract class AnalysisApi {
  Future<Result<AnalyzeResult>> analyze(String text);
}

class HttpAnalysisApi implements AnalysisApi {
  HttpAnalysisApi(this._baseUrl);

  final String _baseUrl;

  @override
  Future<Result<AnalyzeResult>> analyze(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/analyze'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );
      if (response.statusCode != 200) {
        return const Result.failure(NetworkFailure('The server could not analyze this text.'));
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Result.success(AnalyzeResult.fromJson(json));
    } on FormatException {
      return const Result.failure(UnexpectedFailure('Received an unexpected response from the server.'));
    } catch (_) {
      return const Result.failure(NetworkFailure());
    }
  }
}

final analysisApiProvider = Provider<AnalysisApi>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  return HttpAnalysisApi(environment.apiBaseUrl);
});
