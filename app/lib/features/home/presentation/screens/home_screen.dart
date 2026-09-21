import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../analysis/data/models/analyze_result.dart';
import '../../../analysis/data/models/claim_input.dart';
import '../../../analysis/data/models/saved_analysis.dart';
import '../../../analysis/presentation/controllers/saved_analyses_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

const _shareChannel = MethodChannel('com.reasonai.reason_ai/share');

// Input mode: link (Instagram/Facebook) or text (WhatsApp)
enum _InputMode { link, text }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  _InputMode _inputMode = _InputMode.link;
  final _contentController = TextEditingController();
  bool _canAnalyze = false;
  // Holds a share URL received before auth restore finishes.
  String? _pendingShareUrl;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_onContentChanged);
    _shareChannel.setMethodCallHandler(_handleNativeCall);
    _checkPendingShare();
  }

  @override
  void dispose() {
    _contentController.removeListener(_onContentChanged);
    _contentController.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    final canAnalyze = _contentController.text.trim().isNotEmpty;
    if (canAnalyze != _canAnalyze) setState(() => _canAnalyze = canAnalyze);
  }

  Future<void> _checkPendingShare() async {
    try {
      final url = await _shareChannel.invokeMethod<String?>('consumePendingSharedUrl');
      if (url != null && mounted) _applySharedUrl(url);
    } catch (_) {}
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onSharedUrl' && mounted) {
      final url = call.arguments as String?;
      if (url != null) _applySharedUrl(url);
    }
  }

  void _applySharedUrl(String url) {
    if (url.trim().isEmpty) return;
    setState(() {
      _inputMode = _InputMode.link;
      _contentController.text = url;
    });
    // If auth is still restoring, park the URL and wait.
    final auth = ref.read(authProvider);
    if (auth.isLoading || !auth.isAuthenticated) {
      _pendingShareUrl = url;
      return;
    }
    // Auto-trigger analysis when URL arrives via share intent — no tap needed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _analyze();
    });
  }

  ClaimSource _detectSource(String url) {
    if (url.contains('instagram.com')) return ClaimSource.instagram;
    if (url.contains('facebook.com') || url.contains('fb.com') || url.contains('fb.watch')) {
      return ClaimSource.facebook;
    }
    return ClaimSource.instagram;
  }

  void _analyze() {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;
    final source = _inputMode == _InputMode.text
        ? ClaimSource.whatsapp
        : _detectSource(content);
    ref.read(claimInputProvider.notifier).set(ClaimInput(source: source, content: content));
    context.push(RoutePaths.analyzing);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recentItems = ref.watch(savedAnalysesControllerProvider).items;

    // Flush a share URL that arrived before auth restore finished.
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (!next.isLoading && next.isAuthenticated && _pendingShareUrl != null) {
        final url = _pendingShareUrl!;
        _pendingShareUrl = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _applySharedUrl(url);
        });
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: const Text('Veritas', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.workspace_premium_outlined),
            tooltip: 'Plans',
            onPressed: () => context.push(RoutePaths.pricing),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (value) async {
              if (value == 'logout') await ref.read(authProvider.notifier).logout();
            },
            itemBuilder: (_) {
              final user = ref.read(authProvider).user;
              return [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? '', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                      Text(user?.email ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF75777D))),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'logout', child: Text('Log out')),
              ];
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero section
            Container(
              color: const Color(0xFF1E293B),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expose the Truth\nBehind the Claim',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Verified AI-Powered Fact Verification Engine',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Input mode selector
                  Row(
                    children: [
                      Expanded(child: _InputModeCard(
                        icon: Icons.link,
                        label: 'Link',
                        sublabel: 'FB, Instagram, etc.',
                        selected: _inputMode == _InputMode.link,
                        onTap: () => setState(() {
                          _inputMode = _InputMode.link;
                          _contentController.clear();
                        }),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _InputModeCard(
                        icon: Icons.chat_bubble_outline,
                        label: 'Forwarded Text',
                        sublabel: 'WhatsApp, Telegram',
                        selected: _inputMode == _InputMode.text,
                        onTap: () => setState(() {
                          _inputMode = _InputMode.text;
                          _contentController.clear();
                        }),
                      )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Input field
                  TextField(
                    controller: _contentController,
                    maxLines: _inputMode == _InputMode.text ? 4 : 2,
                    style: const TextStyle(color: Color(0xFF191C1E)),
                    decoration: InputDecoration(
                      hintText: _inputMode == _InputMode.link
                          ? 'Paste post URL here…'
                          : 'Paste or type the message…',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: Icon(
                        _inputMode == _InputMode.link ? Icons.language : Icons.message_outlined,
                        color: Colors.grey.shade500,
                      ),
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF006A61), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _canAnalyze ? _analyze : null,
                      icon: const Icon(Icons.verified_outlined, size: 18),
                      label: const Text('Analyze Claim'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _canAnalyze ? const Color(0xFF006A61) : Colors.grey.shade600,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Recent Checks section
            if (recentItems.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  children: [
                    const Icon(Icons.history, size: 18, color: Color(0xFF45474C)),
                    const SizedBox(width: 6),
                    Text('Recent Checks', style: theme.textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF191C1E),
                      fontWeight: FontWeight.w600,
                    )),
                  ],
                ),
              ),
              ...recentItems.take(3).map((saved) => _RecentCheckCard(saved: saved)),
            ],

            // Tip of the day
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFD8E3FB).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBCC7DE)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Color(0xFF1E293B), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tip of the Day', style: theme.textTheme.labelLarge?.copyWith(
                            color: const Color(0xFF1E293B),
                            fontWeight: FontWeight.w600,
                          )),
                          const SizedBox(height: 4),
                          Text(
                            'Check the image metadata — reverse image search can reveal if a photo has been reused from a different context or date.',
                            style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF45474C)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(activeTab: AppNavTab.home),
    );
  }
}

class _InputModeCard extends StatelessWidget {
  const _InputModeCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String sublabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF006A61) : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF006A61) : Colors.white.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: selected ? Colors.white : Colors.white.withValues(alpha: 0.7), size: 20),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            )),
            Text(sublabel, style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
            )),
          ],
        ),
      ),
    );
  }
}

class _RecentCheckCard extends StatelessWidget {
  const _RecentCheckCard({required this.saved});

  final SavedAnalysis saved;

  @override
  Widget build(BuildContext context) {
    final verdict = _deriveVerdict(saved.analysis);
    final (label, color, icon) = _verdictStyle(verdict);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              )),
            ],
          ),
        ),
        title: Text(
          saved.analysis.claim,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          _timeAgo(saved.savedAt),
          style: const TextStyle(fontSize: 11, color: Color(0xFF75777D)),
        ),
      ),
    );
  }

  String _deriveVerdict(AnalyzeResult analysis) {
    final forCount = analysis.evidence.where((e) => e.stance == 'for').length;
    final againstCount = analysis.evidence.where((e) => e.stance == 'against').length;
    if (forCount > againstCount) return 'verified';
    if (againstCount > forCount) return 'misleading';
    return 'mixed';
  }

  (String, Color, IconData) _verdictStyle(String verdict) => switch (verdict) {
        'verified' => ('VERIFIED', const Color(0xFF006A61), Icons.check_circle_outline),
        'misleading' => ('MISLEADING', const Color(0xFFBA1A1A), Icons.warning_amber_outlined),
        _ => ('MIXED', const Color(0xFF856A00), Icons.help_outline),
      };

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
