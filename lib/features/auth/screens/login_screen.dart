import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/neu.dart';

/// Neumorphic login screen for CRM modules.
/// No real auth — dummy credentials are pre-filled.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.returnTo});

  /// Route to navigate after successful login (e.g. '/admission').
  final String? returnTo;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController(text: 'admin@dailathon.com');
  final _passCtrl = TextEditingController(text: 'demo1234');
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _error = null);
    try {
      await AuthService.instance.login(
        username: _userCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (!mounted) return;
      final dest = widget.returnTo ?? '/home';
      context.go(dest);
    } catch (e) {
      setState(() => _error = 'Login failed. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ListenableBuilder(
              listenable: AuthService.instance,
              builder: (context, _) {
                final isLoading = AuthService.instance.loading;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Logo / brand ───────────────────────────────────────
                    Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: AppTheme.bg,
                          shape: BoxShape.circle,
                          boxShadow: AppTheme.raisedShadow(distance: 6, blur: 18),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.phone_in_talk_rounded,
                            color: AppTheme.primary,
                            size: 44,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        'Dailathon',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Center(
                      child: Text(
                        'CRM — Admission Calling',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ── Email field ────────────────────────────────────────
                    const Text(
                      'Email',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    NeuTextField(
                      controller: _userCtrl,
                      hintText: 'your@email.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(Icons.mail_outline_rounded,
                          color: AppTheme.textSecondary, size: 20),
                    ),
                    const SizedBox(height: 20),

                    // ── Password field ─────────────────────────────────────
                    const Text(
                      'Password',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    NeuTextField(
                      controller: _passCtrl,
                      hintText: 'Enter password',
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      prefixIcon: const Icon(Icons.lock_outline_rounded,
                          color: AppTheme.textSecondary, size: 20),
                      suffixIcon: GestureDetector(
                        onTap: () => setState(() => _obscure = !_obscure),
                        child: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppTheme.textSecondary,
                          size: 20,
                        ),
                      ),
                      onFieldSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: 12),

                    // ── Demo note ──────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.07),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: AppTheme.primary, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Demo mode — credentials are pre-filled.',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Error ──────────────────────────────────────────────
                    if (_error != null) ...[
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ── Login button ───────────────────────────────────────
                    isLoading
                        ? const Center(
                            child: SizedBox.square(
                              dimension: 48,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation(
                                    AppTheme.primary),
                                strokeWidth: 2.5,
                              ),
                            ),
                          )
                        : NeuButton(
                            label: 'Sign In',
                            icon: Icons.login_rounded,
                            onPressed: _login,
                            width: double.infinity,
                            height: 54,
                          ),

                    const SizedBox(height: 28),

                    // ── Skip note ──────────────────────────────────────────
                    Center(
                      child: TextButton(
                        onPressed: () => context.go('/home'),
                        child: const Text(
                          'Back to Home',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
