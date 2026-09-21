import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/analysis_api.dart';
import '../../data/chat_repository.dart';
import '../../data/models/analyze_result.dart';
import '../../data/models/chat_message.dart';

class ChatState {
  const ChatState({this.messages = const [], this.isLoading = false, this.error});
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  ChatState copyWith({List<ChatMessage>? messages, bool? isLoading, String? error}) =>
      ChatState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() => const ChatState();

  Future<void> loadFor(AnalyzeResult analysis) async {
    final messages = await ref.read(chatRepositoryProvider).loadFor(analysis.claim);
    state = ChatState(messages: messages);
  }

  void reset() => state = const ChatState();

  Future<void> send({required AnalyzeResult analysis, required String question}) async {
    final userMessage = ChatMessage(role: ChatRole.user, content: question);
    final updatedMessages = [...state.messages, userMessage];
    state = state.copyWith(messages: updatedMessages, isLoading: true, error: null);

    final result = await ref.read(analysisApiProvider).chat(
          analysis: analysis.toJson(),
          history: state.messages.sublist(0, state.messages.length - 1),
          question: question,
        );

    result.when(
      success: (answer) {
        final allMessages = [
          ...state.messages,
          ChatMessage(role: ChatRole.assistant, content: answer),
        ];
        state = state.copyWith(messages: allMessages, isLoading: false);
        unawaited(ref.read(chatRepositoryProvider).saveFor(analysis.claim, allMessages));
      },
      failure: (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
      },
    );
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
