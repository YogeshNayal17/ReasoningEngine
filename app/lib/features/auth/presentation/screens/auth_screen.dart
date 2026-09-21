import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLogin = false;
  bool _obscure = true;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isLogin) {
      await ref.read(authProvider.notifier).login(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
          );
    } else {
      await ref.read(authProvider.notifier).register(
            name: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),

              // Logo + title
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.psychology, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text('Veritas',
                      style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                ],
              ),
              const SizedBox(height: 32),

              Text(
                _isLogin ? 'Welcome back' : 'Create your account',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin
                    ? 'Sign in to continue fact-checking'
                    : 'Start thinking critically about the content you see',
                style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF45474C)),
              ),
              const SizedBox(height: 32),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (!_isLogin) ...[
                      _Field(
                        controller: _nameCtrl,
                        label: 'Full Name',
                        icon: Icons.person_outline,
                        validator: (v) => (v?.trim().isEmpty ?? true) ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    _Field(
                      controller: _emailCtrl,
                      label: 'Email address',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v?.trim().isEmpty ?? true) return 'Email is required';
                        if (!v!.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (!_isLogin && v.length < 8) return 'Minimum 8 characters';
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                        helperText: _isLogin ? null : '8+ chars, 1 number',
                      ),
                    ),
                  ],
                ),
              ),

              // Error
              if (auth.error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFDAD6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(auth.error!,
                      style: const TextStyle(color: Color(0xFF93000A), fontSize: 13)),
                ),
              ],

              const SizedBox(height: 24),

              // Submit button
              FilledButton(
                onPressed: auth.isLoading ? null : _submit,
                child: auth.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_isLogin ? 'Log In' : 'Create Account'),
              ),

              const SizedBox(height: 16),

              // Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLogin ? "Don't have an account? " : 'Already have an account? ',
                    style: const TextStyle(color: Color(0xFF45474C)),
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      _isLogin = !_isLogin;
                      _formKey.currentState?.reset();
                    }),
                    child: Text(
                      _isLogin ? 'Sign up' : 'Log in',
                      style: const TextStyle(
                        color: Color(0xFF006A61),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Security note
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 14, color: Color(0xFF75777D)),
                  const SizedBox(width: 6),
                  Text(
                    'Encrypted & Anonymous Claim Processing',
                    style: theme.textTheme.labelSmall?.copyWith(color: const Color(0xFF75777D)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
      );
}
