import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../auth/presentation/controllers/auth_controller.dart';
import 'models/chat_message.dart';

/// Persists chat histories per user, keyed by the claim text.
/// Stored as a single JSON map: { claimKey -> [messages] }
class ChatRepository {
  ChatRepository(this._userId);

  final int _userId;

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/chats_$_userId.json');
  }

  Future<Map<String, List<ChatMessage>>> _loadAll() async {
    final file = await _file();
    if (!await file.exists()) return {};
    final content = await file.readAsString();
    if (content.trim().isEmpty) return {};
    final raw = jsonDecode(content) as Map<String, dynamic>;
    return raw.map((key, value) {
      final msgs = (value as List<dynamic>)
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList();
      return MapEntry(key, msgs);
    });
  }

  Future<List<ChatMessage>> loadFor(String claim) async {
    final all = await _loadAll();
    return all[_key(claim)] ?? [];
  }

  Future<void> saveFor(String claim, List<ChatMessage> messages) async {
    final all = await _loadAll();
    all[_key(claim)] = messages;
    final file = await _file();
    await file.writeAsString(jsonEncode(
      all.map((k, v) => MapEntry(k, v.map((m) => m.toJson()).toList())),
    ));
  }

  // Truncate long claims to keep file keys sane.
  String _key(String claim) => claim.length > 120 ? claim.substring(0, 120) : claim;
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final userId = ref.watch(authProvider).user?.userId ?? 0;
  return ChatRepository(userId);
});
