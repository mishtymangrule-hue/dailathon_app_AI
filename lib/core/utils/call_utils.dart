import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../service_locator.dart';

class CallUtils {
  /// Places a call through the app's own telecom pipeline
  static Future<void> makeCall(BuildContext context, String number) async {
    // 1. Clean the number
    final cleaned = number.replaceAll(RegExp(r'\s+'), '');

    // 2. Request permission at runtime
    final status = await Permission.phone.request();

    if (status.isGranted) {
      try {
        await ServiceLocator().callMethodChannel.dial(cleaned);
      } catch (e) {
        _showError(context, 'Could not place call.');
      }
    } else if (status.isPermanentlyDenied) {
      // Guide user to settings
      _showSettingsDialog(context);
    } else {
      _showError(context, 'Phone permission denied.');
    }
  }

  /// Opens WhatsApp chat
  static Future<void> openWhatsApp(BuildContext context, String number) async {
    final cleaned = number.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('https://wa.me/$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showError(context, 'WhatsApp is not installed.');
    }
  }

  /// Opens SMS app
  static Future<void> openSms(BuildContext context, String number) async {
    final uri = Uri(scheme: 'sms', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showError(context, 'Could not open SMS app.');
    }
  }

  static void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  static void _showSettingsDialog(BuildContext context) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Phone permission is permanently denied. '
          'Please enable it in Settings to make calls.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings(); // from permission_handler
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
