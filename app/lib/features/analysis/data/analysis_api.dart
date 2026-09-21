import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_environment.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/utils/result.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import 'models/analyze_result.dart';
import 'models/chat_message.dart';

abstract class AnalysisApi {
  Future<Result<AnalyzeResult>> analyze({required String source, required String content});
  Future<Result<String>> chat({
    required Map<String, dynamic> analysis,
    required List<ChatMessage> history,
    required String question,
  });
}

class HttpAnalysisApi implements AnalysisApi {
  HttpAnalysisApi(this._baseUrl, this._token);

  final String _baseUrl;
  final String? _token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  @override
  Future<Result<AnalyzeResult>> analyze({required String source, required String content}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/analyze'),
        headers: _headers,
        body: jsonEncode({'source': source, 'content': content}),
      );
      if (response.statusCode == 429) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return Result.failure(NetworkFailure(json['detail'] as String? ?? 'Daily limit reached.'));
      }
      if (response.statusCode != 200) {
        try {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          final detail = json['detail'] as String?;
          if (detail != null) return Result.failure(NetworkFailure(detail));
        } catch (_) {}
        return const Result.failure(NetworkFailure('The server could not analyze this content.'));
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Result.success(AnalyzeResult.fromJson(json));
    } on FormatException {
      return const Result.failure(UnexpectedFailure('Received an unexpected response from the server.'));
    } catch (_) {
      return const Result.failure(NetworkFailure());
    }
  }

  @override
  Future<Result<String>> chat({
    required Map<String, dynamic> analysis,
    required List<ChatMessage> history,
    required String question,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: _headers,
        body: jsonEncode({
          'analysis': analysis,
          'history': history.map((m) => m.toJson()).toList(),
          'question': question,
        }),
      );
      if (response.statusCode == 429) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return Result.failure(NetworkFailure(json['detail'] as String? ?? 'Daily limit reached.'));
      }
      if (response.statusCode != 200) {
        return const Result.failure(NetworkFailure('The server could not answer this question.'));
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Result.success(json['answer'] as String);
    } on FormatException {
      return const Result.failure(UnexpectedFailure('Received an unexpected response from the server.'));
    } catch (_) {
      return const Result.failure(NetworkFailure());
    }
  }
}

final analysisApiProvider = Provider<AnalysisApi>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  final token = ref.watch(authProvider).user?.token;
  return HttpAnalysisApi(environment.apiBaseUrl, token);
});
