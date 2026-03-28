import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_theme.dart';

/// Blocking permission gate that prevents app access until all required
/// permissions are granted.  If any is denied the user sees an explanation
/// screen and can retry or open system settings.
class PermissionGateScreen extends StatefulWidget {
  final Widget child;
  const PermissionGateScreen({Key? key, required this.child}) : super(key: key);

  @override
  State<PermissionGateScreen> createState() => _PermissionGateScreenState();
}

class _PermissionGateScreenState extends State<PermissionGateScreen>
    with WidgetsBindingObserver {
  bool _checking = true;
  bool _allGranted = false;
  final List<_PermissionInfo> _denied = [];

  static const _required = <Permission>[
    Permission.phone,
    Permission.contacts,
    Permission.notification,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAndRequest();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-check when returning from system settings.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_allGranted) {
      _checkOnly();
    }
  }

  Future<void> _checkAndRequest() async {
    setState(() { _checking = true; _denied.clear(); });

    final statuses = await _required.request();

    _evaluateStatuses(statuses);
  }

  /// Silent check (no system dialog) — used when returning from settings.
  Future<void> _checkOnly() async {
    setState(() { _checking = true; _denied.clear(); });

    final Map<Permission, PermissionStatus> statuses = {};
    for (final p in _required) {
      statuses[p] = await p.status;
    }

    _evaluateStatuses(statuses);
  }

  void _evaluateStatuses(Map<Permission, PermissionStatus> statuses) {
    final denied = <_PermissionInfo>[];

    for (final entry in statuses.entries) {
      if (!entry.value.isGranted) {
        denied.add(_PermissionInfo(
          permission: entry.key,
          label: _label(entry.key),
          description: _description(entry.key),
          icon: _icon(entry.key),
          permanentlyDenied: entry.value.isPermanentlyDenied,
        ));
      }
    }

    setState(() {
      _checking = false;
      _allGranted = denied.isEmpty;
      _denied
        ..clear()
        ..addAll(denied);
    });
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  static String _label(Permission p) {
    switch (p) {
      case Permission.phone:
        return 'Phone';
      case Permission.contacts:
        return 'Contacts';
      case Permission.notification:
        return 'Notifications';
      default:
        return p.toString();
    }
  }

  static String _description(Permission p) {
    switch (p) {
      case Permission.phone:
        return 'Required to make and manage calls.';
      case Permission.contacts:
        return 'Required to access your contact list.';
      case Permission.notification:
        return 'Required to alert you of incoming calls.';
      default:
        return 'This permission is required for the app to function.';
    }
  }

  static IconData _icon(Permission p) {
    switch (p) {
      case Permission.phone:
        return Icons.phone_rounded;
      case Permission.contacts:
        return Icons.contacts_rounded;
      case Permission.notification:
        return Icons.notifications_rounded;
      default:
        return Icons.security_rounded;
    }
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: Color(0xFFE0E5EC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_allGranted) return widget.child;

    final hasPermanent = _denied.any((d) => d.permanentlyDenied);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Icon(Icons.shield_rounded, size: 72, color: AppTheme.primary),
              const SizedBox(height: 20),
              const Text(
                'Permissions Required',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Dailathon needs these permissions to work.\nPlease grant all of them to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              // List of denied permissions
              ...List.generate(_denied.length, (i) {
                final info = _denied[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(info.icon, color: AppTheme.primary, size: 28),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                info.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                info.description,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          info.permanentlyDenied
                              ? Icons.block_rounded
                              : Icons.close_rounded,
                          color: Colors.redAccent,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const Spacer(flex: 3),
              // Action buttons
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Icon(hasPermanent
                      ? Icons.settings_rounded
                      : Icons.check_circle_rounded),
                  label: Text(
                    hasPermanent
                        ? 'Open App Settings'
                        : 'Grant Permissions',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () {
                    if (hasPermanent) {
                      openAppSettings();
                    } else {
                      _checkAndRequest();
                    }
                  },
                ),
              ),
              if (hasPermanent) ...[
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _checkOnly,
                  child: const Text('I\'ve enabled them — Recheck'),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionInfo {
  final Permission permission;
  final String label;
  final String description;
  final IconData icon;
  final bool permanentlyDenied;
  const _PermissionInfo({
    required this.permission,
    required this.label,
    required this.description,
    required this.icon,
    required this.permanentlyDenied,
  });
}
