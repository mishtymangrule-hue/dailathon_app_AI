import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

/// PermissionManager handles all runtime permission requests and checks.
/// Provides graceful denial handling with recovery UI.
class PermissionManager {
  /// Request all required permissions for the dialer app.
  static Future<bool> requestAllPermissions(BuildContext context) async {
    final permissions = <Permission>[
      Permission.phone,
      Permission.contacts,
      if (await _isApi33OrAbove()) Permission.notification,
    ];

    final statuses =
        await permissions.request();

    // Check if all permissions were granted
    final allGranted = statuses.values.every(
      (status) => status.isGranted,
    );

    if (!allGranted) {
      // Find first denied permission
      final deniedPerm = statuses.entries
          .firstWhere(
            (e) => !e.value.isGranted,
            orElse: () => statuses.entries.first,
          )
          .key;

      if (statuses[deniedPerm]?.isDenied ?? false) {
        _showPermissionDenialDialog(context, deniedPerm);
      } else if (statuses[deniedPerm]?.isPermanentlyDenied ?? false) {
        _showPermissionPermanentlyDeniedDialog(context, deniedPerm);
      }
    }

    return allGranted;
  }

  /// Check if specific permission is granted.
  static Future<bool> isPermissionGranted(Permission permission) async {
    final status = await permission.status;
    return status.isGranted;
  }

  /// Request a single permission with context-aware handling.
  static Future<bool> requestPermission(
    BuildContext context,
    Permission permission,
  ) async {
    final status = await permission.request();

    if (status.isDenied) {
      _showPermissionDenialDialog(context, permission);
      return false;
    } else if (status.isPermanentlyDenied) {
      _showPermissionPermanentlyDeniedDialog(context, permission);
      return false;
    }

    return status.isGranted;
  }

  /// Show dialog for denied permission with retry option.
  static void _showPermissionDenialDialog(
    BuildContext context,
    Permission permission,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text(
          _getPermissionDescription(permission),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              requestPermission(context, permission);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Show dialog for permanently denied permission with settings link.
  static void _showPermissionPermanentlyDeniedDialog(
    BuildContext context,
    Permission permission,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permission Permanently Denied'),
        content: Text(
          '${_getPermissionDescription(permission)}\n\nPlease enable it in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Get human-readable description for permission.
  static String _getPermissionDescription(Permission permission) {
    switch (permission) {
      case Permission.phone:
        return 'Phone permission is required to make and manage calls.';
      case Permission.contacts:
        return 'Contacts permission is required to access your contact list.';
      case Permission.notification:
        return 'Notification permission is required to alert you of incoming calls.';
      default:
        return 'This permission is required for the app to function.';
    }
  }

  /// Check if device runs Android API 33 or above.
  static Future<bool> _isApi33OrAbove() async {
    if (!Platform.isAndroid) return false;
    // In real scenario, use device_info_plus plugin
    // For now, assume API 33+ (can be enhanced later)
    return true;
  }

  /// Check if POST_NOTIFICATIONS permission is available (Android 13+).
  static Future<bool> shouldRequestNotificationPermission() async => await _isApi33OrAbove();
}
