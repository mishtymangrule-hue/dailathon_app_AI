import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/channels/call_method_channel.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/neu.dart';

/// Hard gate: blocks all app content until Dailathon is the system default
/// dialer. The user cannot bypass this screen â€” no skip, no dismiss.
///
/// Uses TelecomManager.ACTION_CHANGE_DEFAULT_DIALER (intent-based, API 29+).
/// RoleManager / ROLE_DIALER is intentionally NOT used.
/// When the user returns to the app the check is re-run automatically.
class DefaultDialerGateScreen extends StatefulWidget {
  const DefaultDialerGateScreen({
    super.key,
    required this.channel,
    required this.child,
  });

  final CallMethodChannel channel;
  final Widget child;

  @override
  State<DefaultDialerGateScreen> createState() =>
      _DefaultDialerGateScreenState();
}

class _DefaultDialerGateScreenState extends State<DefaultDialerGateScreen>
    with WidgetsBindingObserver {

  bool _checking = true;
  bool _isDefault = false;
  bool _requesting = false;  // prevents concurrent setDefaultDialer calls

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check whenever the user returns from the system dialog.
    if (state == AppLifecycleState.resumed && !_isDefault) {
      _check();
    }
  }

  Future<void> _check() async {
    setState(() => _checking = true);
    try {
      final result = await widget.channel.checkDefaultDialer();
      setState(() {
        _isDefault = result;
        _checking = false;
      });
    } catch (_) {
      // If the channel call fails (e.g. during cold start), retry in 500 ms.
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted) _check();
    }
  }

  Future<void> _requestDefault() async {
    if (_requesting) return;  // debounce
    setState(() => _requesting = true);
    try {
      await widget.channel.setDefaultDialer();
    } on Exception catch (e) {
      // Surface the error so it's visible — silent failure is the wrong behavior here.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open default dialer dialog: $e'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
    // Re-check after a short delay to allow the system dialog to complete.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    setState(() => _requesting = false);
    if (mounted) _check();
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const _CheckSplash();
    }
    if (_isDefault) return widget.child;
    return _DefaultDialerBlocker(onRequest: _requestDefault);
  }
}

//  Splash while checking 

class _CheckSplash extends StatelessWidget {
  const _CheckSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(
        child: CircularProgressIndicator(
          color: AppTheme.primary,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}

//  Blocker screen 

class _DefaultDialerBlocker extends StatefulWidget {
  const _DefaultDialerBlocker({required this.onRequest});
  final VoidCallback onRequest;

  @override
  State<_DefaultDialerBlocker> createState() => _DefaultDialerBlockerState();
}

class _DefaultDialerBlockerState extends State<_DefaultDialerBlocker>
    with SingleTickerProviderStateMixin {

  late final AnimationController _enter;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(parent: _enter, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enter, curve: Curves.easeOut));
    _enter.forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),

                  //  Icon 
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppTheme.bg,
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.raisedShadow(distance: 7, blur: 20),
                      ),
                      child: const Icon(
                        Icons.phone_in_talk_rounded,
                        size: 42,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  //  Title 
                  const Text(
                    'Set Dailathon as\nDefault Dialer',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Dailathon must be your default Phone app to place and receive calls, manage your contacts, and access full call features.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 36),

                  //  Feature bullets 
                  _Bullet(
                    icon: Icons.call_rounded,
                    text: 'Place and receive all calls',
                  ),
                  const SizedBox(height: 10),
                  _Bullet(
                    icon: Icons.history_rounded,
                    text: 'Access your complete call history',
                  ),
                  const SizedBox(height: 10),
                  _Bullet(
                    icon: Icons.notifications_active_rounded,
                    text: 'Show incoming-call screen over lock screen',
                  ),

                  const Spacer(flex: 3),

                  //  CTA button 
                  GestureDetector(
                    onTap: widget.onRequest,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.40),
                            blurRadius: 18,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified_rounded,
                              color: Colors.white, size: 22),
                          SizedBox(width: 10),
                          Text(
                            'Set as Default Dialer',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppTheme.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
