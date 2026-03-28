import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/neu.dart';

/// Hard gate: the app cannot be used until every mandatory runtime permission
/// is granted AND battery optimization is disabled.
///
/// First launch: fires a consolidated system permission request for all
/// mandatory permissions. User must grant all to proceed.
/// Subsequent launches / resumes: silently checks status only. If any
/// permission is missing, blocks the app and directs to device Settings.
/// Permissions are never requestable from inside the app after onboarding.
class PermissionGateScreen extends StatefulWidget {
  const PermissionGateScreen({super.key, required this.child});
  final Widget child;

  @override
  State<PermissionGateScreen> createState() => _PermissionGateScreenState();
}

class _PermissionGateScreenState extends State<PermissionGateScreen>
    with WidgetsBindingObserver {

  // Key persisted across launches to track whether onboarding request was shown.
  static const _kOnboardingKey = 'perm_onboarding_done';

  // Mandatory runtime permissions (per product spec).
  // RECORD_AUDIO and call-forwarding intentionally excluded.
  static const _required = <Permission>[
    Permission.phone,                      // CALL_PHONE, READ_PHONE_STATE,
                                           // READ_CALL_LOG, WRITE_CALL_LOG
    Permission.contacts,                   // READ_CONTACTS, WRITE_CONTACTS
    Permission.notification,               // POST_NOTIFICATIONS (API 33+)
    Permission.ignoreBatteryOptimizations, // Keeps call services alive
  ];

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  bool _checking = true;
  bool _allGranted = false;
  List<_PermEntry> _denied = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Defer so the Flutter Activity is fully attached before any permission call.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initCheck();
    });
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

  /// Entry point: first launch requests all permissions; subsequent launches
  /// only check status silently.
  Future<void> _initCheck() async {
    final done = await _storage.read(key: _kOnboardingKey);
    if (done == 'true') {
      _checkOnly();
    } else {
      _requestAll();
    }
  }

  /// First-launch only: fire system permission dialogs for all required
  /// permissions in sequence, then persist the onboarding flag.
  Future<void> _requestAll() async {
    if (!mounted) return;
    setState(() { _checking = true; });
    // Give the Android Activity time to attach to the permission plugin.
    // Without this delay, permission_handler reports "Unable to detect Activity".
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    try {
      final statuses = await _required.request();
      // Mark onboarding done regardless of outcome — on denial the blocker
      // screen will direct the user to Settings, not re-request in-app.
      await _storage.write(key: _kOnboardingKey, value: 'true');
      _evaluate(statuses);
    } catch (_) {
      // If request fails (e.g. Activity not ready), leave onboarding flag unset
      // so it retries the request next launch, and silently check now.
      if (mounted) _checkOnly();
    }
  }

  Future<void> _checkOnly() async {
    if (!mounted) return;
    setState(() { _checking = true; });
    try {
      final statuses = <Permission, PermissionStatus>{};
      for (final p in _required) {
        statuses[p] = await p.status;
      }
      _evaluate(statuses);
    } catch (_) {
      if (mounted) setState(() { _checking = false; });
    }
  }

  void _evaluate(Map<Permission, PermissionStatus> statuses) {
    final denied = <_PermEntry>[];
    for (final entry in statuses.entries) {
      if (!entry.value.isGranted) {
        denied.add(_PermEntry(permission: entry.key));
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
    required this.onRecheck,
  });

  final List<_PermEntry> denied;
  final VoidCallback onRecheck;

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
              const Text(
                'The following permissions are required for Dailathon to function. '
                'Enable them in device Settings, then return to the app.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: ListView.separated(
                  itemCount: denied.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _PermCard(entry: denied[i]),
                ),
              ),
              const SizedBox(height: 24),
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
                    "I've enabled them \u2192 Recheck",
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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
              color: AppTheme.errorColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(
              entry.icon,
              size: 22,
              color: AppTheme.errorColor,
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
          const Icon(
            Icons.block_rounded,
            size: 18,
            color: AppTheme.errorColor,
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
  const _PermEntry({required this.permission});

  final Permission permission;

  String get label {
    switch (permission) {
      case Permission.phone:        return 'Phone & Call Log';
      case Permission.contacts:     return 'Contacts';
      case Permission.notification: return 'Notifications';
      case Permission.ignoreBatteryOptimizations: return 'Battery Optimization';
      default:                      return 'Permission';
    }
  }

  String get description {
    switch (permission) {
      case Permission.phone:
        return 'Required to place calls, read phone state, and access call history.';
      case Permission.contacts:
        return 'Required to display and manage contacts in the dialer.';
      case Permission.notification:
        return 'Required to display incoming and missed call alerts.';
      case Permission.ignoreBatteryOptimizations:
        return 'Required to keep call services running reliably in the background.';
      default:
        return 'Required for core app functionality.';
    }
  }

  IconData get icon {
    switch (permission) {
      case Permission.phone:        return Icons.phone_rounded;
      case Permission.contacts:     return Icons.contacts_rounded;
      case Permission.notification: return Icons.notifications_rounded;
      case Permission.ignoreBatteryOptimizations: return Icons.battery_saver_rounded;
      default:                      return Icons.security_rounded;
    }
  }
}