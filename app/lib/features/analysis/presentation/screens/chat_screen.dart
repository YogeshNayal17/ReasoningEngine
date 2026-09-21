import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../data/models/chat_message.dart';
import '../controllers/analysis_controller.dart';
import '../controllers/chat_controller.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load persisted chat for the current analysis after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final analysis = ref.read(analysisControllerProvider).result?.when(
            success: (v) => v,
            failure: (_) => null,
          );
      if (analysis != null) {
        ref.read(chatProvider.notifier).loadFor(analysis);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final analysis = ref.read(analysisControllerProvider).result?.when(
          success: (v) => v,
          failure: (_) => null,
        );
    if (analysis == null) return;
    _controller.clear();
    ref.read(chatProvider.notifier).send(analysis: analysis, question: text);
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatProvider);
    final theme = Theme.of(context);

    ref.listen(chatProvider, (_, next) {
      if (!next.isLoading) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Follow-up', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          if (chat.messages.isEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 48, color: theme.colorScheme.outline),
                      const SizedBox(height: 16),
                      Text(
                        'Ask anything about this analysis',
                        style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                itemCount: chat.messages.length + (chat.isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == chat.messages.length) {
                    return const _TypingIndicator();
                  }
                  return _MessageBubble(message: chat.messages[index]);
                },
              ),
            ),
          if (chat.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                chat.error!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
              ),
            ),
          _InputBar(
            controller: _controller,
            isLoading: chat.isLoading,
            onSend: _send,
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(activeTab: AppNavTab.reasoning),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF1E293B) : const Color(0xFFF2F4F6),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: isUser
            ? Text(
                message.content,
                style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.5),
              )
            : MarkdownBody(
                data: message.content,
                onTapLink: (text, href, title) async {
                  if (href == null) return;
                  final uri = Uri.tryParse(href);
                  if (uri != null) await launchUrl(uri);
                },
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(fontSize: 14, color: Color(0xFF191C1E), height: 1.5),
                  strong: const TextStyle(fontSize: 14, color: Color(0xFF191C1E), fontWeight: FontWeight.w700),
                  em: const TextStyle(fontSize: 14, color: Color(0xFF191C1E), fontStyle: FontStyle.italic),
                  code: const TextStyle(fontSize: 13, color: Color(0xFF191C1E), backgroundColor: Color(0xFFE2E8F0)),
                  listBullet: const TextStyle(fontSize: 14, color: Color(0xFF191C1E)),
                  h3: const TextStyle(fontSize: 15, color: Color(0xFF191C1E), fontWeight: FontWeight.w700),
                ),
              ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const SizedBox(
          width: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Dot(delay: 0),
              _Dot(delay: 150),
              _Dot(delay: 300),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.delay});
  final int delay;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _opacity = CurvedAnimation(
      parent: _anim,
      curve: Interval(widget.delay / 900, (widget.delay + 400) / 900, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(color: Color(0xFF75777D), shape: BoxShape.circle),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.isLoading, required this.onSend});
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isLoading,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Ask a follow-up question…',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: isLoading ? null : onSend,
              icon: isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded),
              style: IconButton.styleFrom(backgroundColor: const Color(0xFF006A61)),
            ),
          ],
        ),
      ),
    );
  }
}
