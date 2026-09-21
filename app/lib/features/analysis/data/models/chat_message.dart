enum ChatRole { user, assistant }

class ChatMessage {
  const ChatMessage({required this.role, required this.content});
  final ChatRole role;
  final String content;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role: ChatRole.values.byName(json['role'] as String),
        content: json['content'] as String,
      );

  Map<String, dynamic> toJson() => {
        'role': role.name,
        'content': content,
      };
}
