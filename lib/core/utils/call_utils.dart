import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../service_locator.dart';
import 'permission_checker.dart';

class CallUtils {
  /// Places a call through the app's own telecom pipeline
  static Future<void> makeCall(BuildContext context, String number) async {
    final raw = number.trim();
    if (raw.isEmpty) {
      _showError(context, 'Please enter a phone number first.');
      return;
    }

    final hasPermission = await PermissionChecker.ensureCallPermission(context);
    if (!hasPermission) return;

    // Keep leading '+' but strip other formatting chars.
    String cleaned = raw;
    if (!cleaned.startsWith('+')) {
      cleaned = cleaned.replaceAll(RegExp(r'[^\d]'), '');
    } else {
      cleaned = '+${cleaned.substring(1).replaceAll(RegExp(r'[^\d]'), '')}';
    }
    if (cleaned.isEmpty) {
      _showError(context, 'Invalid phone number format.');
      return;
    }

    try {
      // Primary path: native Telecom integration for in-call controls.
      await ServiceLocator().callMethodChannel.dial(cleaned);
      return;
    } catch (e) {
      debugPrint('Native dial failed, falling back to tel URI: $e');
    }

    // Fallback: direct tel: launch so call placement still works.
    final Uri telUri = Uri(scheme: 'tel', path: cleaned);
    try {
      final canLaunch = await canLaunchUrl(telUri);
      if (canLaunch) {
        final launched = await launchUrl(telUri);
        if (!launched) {
          _showError(context, 'Call failed to launch. Please try again.');
        }
      } else {
        // Some OEM ROMs return false incorrectly; attempt launch directly.
        final launched = await launchUrl(telUri);
        if (!launched) {
          _showError(context, 'Cannot initiate call on this device.');
        }
      }
    } catch (e) {
      _showError(context, 'Error making call: $e');
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
}
