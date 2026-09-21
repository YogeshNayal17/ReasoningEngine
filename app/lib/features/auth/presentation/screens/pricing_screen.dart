import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/app_bottom_nav.dart';
import '../controllers/auth_controller.dart';

class PricingScreen extends ConsumerStatefulWidget {
  const PricingScreen({super.key});

  @override
  ConsumerState<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends ConsumerState<PricingScreen> {
  bool _upgrading = false;

  Future<void> _upgrade() async {
    setState(() => _upgrading = true);
    await ref.read(authProvider.notifier).upgrade();
    setState(() => _upgrading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are now on the Nerd plan!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isNerd = auth.user?.isNerd ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: const Text('Plans', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              'Choose your plan',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Daily quotas reset at 00:00 UTC',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF75777D)),
            ),
            const SizedBox(height: 24),

            // Basic card
            _PlanCard(
              name: 'Basic',
              price: '₹0',
              priceSub: 'Free forever',
              isActive: !isNerd,
              isRecommended: false,
              features: const [
                _Feature('5 analyses per day', true),
                _Feature('20 follow-up questions per day', true),
                _Feature('Standard source credibility check', true),
                _Feature('Basic bias identification', true),
                _Feature('Primary archive access', false),
                _Feature('Audit report export', false),
              ],
              action: !isNerd
                  ? _ActiveBadge()
                  : null,
            ),
            const SizedBox(height: 16),

            // Nerd card
            _PlanCard(
              name: 'Nerd',
              price: '₹99',
              priceSub: '/month · \$2 globally',
              isActive: isNerd,
              isRecommended: true,
              features: const [
                _Feature('50 analyses per day  (10×)', true),
                _Feature('200 follow-up questions per day', true),
                _Feature('Priority source triangulation', true),
                _Feature('Primary archive lookup', true),
                _Feature('Comprehensive fallacy analysis', true),
                _Feature('Emotional manipulation detection', true),
                _Feature('Audit report export', true),
                _Feature('Claim evaluation matrix', true),
              ],
              action: isNerd
                  ? _ActiveBadge()
                  : FilledButton(
                      onPressed: _upgrading ? null : _upgrade,
                      child: _upgrading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Upgrade to Nerd'),
                    ),
            ),
            const SizedBox(height: 24),

            // Payment note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFECEEF0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, size: 14, color: Color(0xFF75777D)),
                      SizedBox(width: 6),
                      Text(
                        'Encrypted 256-bit payments',
                        style: TextStyle(fontSize: 12, color: Color(0xFF75777D), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'UPI, Cards & NetBanking · No lock-in commitment',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: const Color(0xFF75777D)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(activeTab: AppNavTab.home),
    );
  }
}

class _Feature {
  const _Feature(this.label, this.included);
  final String label;
  final bool included;
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.name,
    required this.price,
    required this.priceSub,
    required this.isActive,
    required this.isRecommended,
    required this.features,
    required this.action,
  });

  final String name;
  final String price;
  final String priceSub;
  final bool isActive;
  final bool isRecommended;
  final List<_Feature> features;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final border = isRecommended
        ? Border.all(color: const Color(0xFF006A61), width: 2)
        : Border.all(color: const Color(0xFFE2E8F0));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: border,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color: isRecommended ? const Color(0xFF1E293B) : const Color(0xFFF2F4F6),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isRecommended)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF006A61),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'RECOMMENDED FOR CRITICAL THINKERS',
                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                    ),
                  ),
                Row(
                  children: [
                    if (isRecommended)
                      const Icon(Icons.star_rounded, color: Color(0xFF86F2E4), size: 18),
                    if (isRecommended) const SizedBox(width: 6),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isRecommended ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: isRecommended ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        priceSub,
                        style: TextStyle(
                          fontSize: 12,
                          color: isRecommended ? Colors.white70 : const Color(0xFF75777D),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Features
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...features.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Icon(
                            f.included ? Icons.check_circle_outline : Icons.remove_circle_outline,
                            size: 16,
                            color: f.included ? const Color(0xFF006A61) : const Color(0xFFC5C6CD),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              f.label,
                              style: TextStyle(
                                fontSize: 13,
                                color: f.included ? const Color(0xFF191C1E) : const Color(0xFF75777D),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                if (action != null) ...[
                  const SizedBox(height: 4),
                  action!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFECEEF0),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 16, color: Color(0xFF006A61)),
            SizedBox(width: 6),
            Text('Current Plan', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF006A61), fontSize: 14)),
          ],
        ),
      );
}
