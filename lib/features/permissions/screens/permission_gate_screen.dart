import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/neu.dart';

/// Hard gate: the app cannot be used until every required runtime permission
/// is granted. Battery-optimisation and call-forwarding are intentionally
/// excluded because they are either non-runtime grants or optional features.
///
/// Layout when permissions are missing:
///    Full-screen blocking UI listing every missing permission
///    "Grant permissions" triggers the system dialog immediately
///    If any are permanently denied  "Open App Settings" + re-check button
///    No skip / dismiss option
class PermissionGateScreen extends StatefulWidget {
  const PermissionGateScreen({super.key, required this.child});
  final Widget child;

  @override
  State<PermissionGateScreen> createState() => _PermissionGateScreenState();
}

class _PermissionGateScreenState extends State<PermissionGateScreen>
    with WidgetsBindingObserver {

  //  Required runtime permissions 
  // Call forwarding and battery optimisation are intentionally excluded.
  static const _required = <Permission>[
    Permission.phone,          // CALL_PHONE + READ_PHONE_STATE
    Permission.microphone,     // RECORD_AUDIO (active call audio)
    Permission.contacts,       // READ_CONTACTS
    Permission.notification,   // POST_NOTIFICATIONS (API 33+)
  ];

  bool _checking = true;
  bool _allGranted = false;
  List<_PermEntry> _denied = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestAll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_allGranted) {
      _checkOnly();
    }
  }

  //  Permission logic 

  Future<void> _requestAll() async {
    setState(() { _checking = true; });
    final statuses = await _required.request();
    _evaluate(statuses);
  }

  Future<void> _checkOnly() async {
    setState(() { _checking = true; });
    final statuses = <Permission, PermissionStatus>{};
    for (final p in _required) {
      statuses[p] = await p.status;
    }
    _evaluate(statuses);
  }

  void _evaluate(Map<Permission, PermissionStatus> statuses) {
    final denied = <_PermEntry>[];
    for (final entry in statuses.entries) {
      if (!entry.value.isGranted) {
        denied.add(_PermEntry(
          permission: entry.key,
          permanentlyDenied: entry.value.isPermanentlyDenied,
        ));
      }
    }
    setState(() {
      _checking = false;
      _allGranted = denied.isEmpty;
      _denied = denied;
    });
  }

  //  Build 

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const _SplashCheck();
    }
    if (_allGranted) return widget.child;
    return _PermissionBlocker(
      denied: _denied,
      onGrant: _requestAll,
      onRecheck: _checkOnly,
    );
  }
}

//  Splash while checking 

class _SplashCheck extends StatelessWidget {
  const _SplashCheck();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5),
            SizedBox(height: 18),
            Text(
              'Checking permissions',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//  Blocker screen 

class _PermissionBlocker extends StatelessWidget {
  const _PermissionBlocker({
    required this.denied,
    required this.onGrant,
    required this.onRecheck,
  });

  final List<_PermEntry> denied;
  final VoidCallback onGrant;
  final VoidCallback onRecheck;

  bool get _hasPermanent => denied.any((e) => e.permanentlyDenied);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              //  Header 
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.bg,
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.raisedShadow(distance: 6, blur: 16),
                ),
                child: const Icon(Icons.security_rounded,
                    size: 34, color: AppTheme.primary),
              ),
              const SizedBox(height: 20),
              const Text(
                'Permissions Required',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _hasPermanent
                    ? 'Some permissions were permanently denied. Open App Settings and enable them manually, then return here.'
                    : 'Dailathon requires the following permissions to place and receive calls. All must be granted to continue.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              //  Permission cards 
              Expanded(
                child: ListView.separated(
                  itemCount: denied.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _PermCard(entry: denied[i]),
                ),
              ),
              const SizedBox(height: 24),
              //  Action buttons 
              if (_hasPermanent) ...[
                _PrimaryButton(
                  label: 'Open App Settings',
                  icon: Icons.settings_rounded,
                  onTap: openAppSettings,
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: onRecheck,
                    child: const Text(
                      'I\'ve enabled them â€” Recheck',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ] else
                _PrimaryButton(
                  label: 'Grant Permissions',
                  icon: Icons.check_circle_rounded,
                  onTap: onGrant,
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

//  Individual permission card 

class _PermCard extends StatelessWidget {
  const _PermCard({required this.entry});
  final _PermEntry entry;

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: entry.permanentlyDenied
                  ? AppTheme.errorColor.withValues(alpha: 0.12)
                  : AppTheme.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(
              entry.icon,
              size: 22,
              color: entry.permanentlyDenied
                  ? AppTheme.errorColor
                  : AppTheme.warning,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            entry.permanentlyDenied
                ? Icons.block_rounded
                : Icons.warning_amber_rounded,
            size: 18,
            color: entry.permanentlyDenied
                ? AppTheme.errorColor
                : AppTheme.warning,
          ),
        ],
      ),
    );
  }
}

//  Primary button 

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.38),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//  Data model 

class _PermEntry {
  const _PermEntry({
    required this.permission,
    required this.permanentlyDenied,
  });

  final Permission permission;
  final bool permanentlyDenied;

  String get label {
    switch (permission) {
      case Permission.phone:        return 'Phone';
      case Permission.microphone:   return 'Microphone';
      case Permission.contacts:     return 'Contacts';
      case Permission.notification: return 'Notifications';
      default:                      return 'Permission';
    }
  }

  String get description {
    switch (permission) {
      case Permission.phone:
        return 'Required to place and manage phone calls.';
      case Permission.microphone:
        return 'Required for call audio during active calls.';
      case Permission.contacts:
        return 'Required to show your contacts in the dialer.';
      case Permission.notification:
        return 'Required to display incoming call alerts.';
      default:
        return 'Required for core app functionality.';
    }
  }

  IconData get icon {
    switch (permission) {
      case Permission.phone:        return Icons.phone_rounded;
      case Permission.microphone:   return Icons.mic_rounded;
      case Permission.contacts:     return Icons.contacts_rounded;
      case Permission.notification: return Icons.notifications_rounded;
      default:                      return Icons.security_rounded;
    }
  }
}
