import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionChecker {
  static Future<void> requestAllPermissionsOnLaunch() async {
    final results = await [
      Permission.phone,
      Permission.contacts,
      Permission.microphone,
      Permission.notification,
    ].request();

    for (final entry in results.entries) {
      debugPrint('Permission [${entry.key}] = ${entry.value}');
    }
  }

  static Future<bool> ensureCallPermission(BuildContext context) async {
    PermissionStatus status = await Permission.phone.status;
    debugPrint('CALL_PHONE permission status: $status');

    if (status.isGranted) return true;

    if (status.isDenied) {
      status = await Permission.phone.request();
      debugPrint('CALL_PHONE after request: $status');
      return status.isGranted;
    }

    if (status.isPermanentlyDenied) {
      await _showPermanentDenialDialog(context);
      return false;
    }

    if (status.isRestricted) {
      _showSnackbar(context, 'Call permission is restricted by device policy.');
      return false;
    }

    return false;
  }

  static Future<void> _showPermanentDenialDialog(BuildContext context) async {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Phone Permission Required'),
        content: const Text(
          'This app needs Phone permission to make calls.\n\n'
          'It was permanently denied. Please open Settings and enable Phone permission.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  static void _showSnackbar(BuildContext context, String msg) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
