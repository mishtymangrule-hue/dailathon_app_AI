import 'package:flutter/material.dart';

/// In-app toast/banner system for showing contextual notifications.
///
/// Usage:
/// ```dart
/// AppToast.show(context, message: 'Call synced', type: ToastType.success);
/// AppToast.error(context, 'Failed to sync call data');
/// AppToast.info(context, 'New lead assigned');
/// ```
enum ToastType { success, error, warning, info }

class AppToast {
  AppToast._();

  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_iconFor(type), color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: _colorFor(type),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: duration,
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction ?? () {},
              )
            : null,
      ),
    );
  }

  static void success(BuildContext context, String message) =>
      show(context, message: message, type: ToastType.success);

  static void error(BuildContext context, String message) =>
      show(context, message: message, type: ToastType.error);

  static void warning(BuildContext context, String message) =>
      show(context, message: message, type: ToastType.warning);

  static void info(BuildContext context, String message) =>
      show(context, message: message, type: ToastType.info);

  static void banner(
    BuildContext context, {
    required String title,
    required String message,
    ToastType type = ToastType.info,
    VoidCallback? onDismiss,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.showMaterialBanner(
      MaterialBanner(
        backgroundColor: _colorFor(type).withValues(alpha: 0.12),
        leading: Icon(_iconFor(type), color: _colorFor(type)),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _colorFor(type),
                    fontSize: 14)),
            Text(message, style: const TextStyle(fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              messenger.hideCurrentMaterialBanner();
              onDismiss?.call();
            },
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  static Color _colorFor(ToastType type) {
    switch (type) {
      case ToastType.success:
        return const Color(0xFF4CAF50);
      case ToastType.error:
        return const Color(0xFFF44336);
      case ToastType.warning:
        return const Color(0xFFFF9800);
      case ToastType.info:
        return const Color(0xFF2196F3);
    }
  }

  static IconData _iconFor(ToastType type) {
    switch (type) {
      case ToastType.success:
        return Icons.check_circle;
      case ToastType.error:
        return Icons.error;
      case ToastType.warning:
        return Icons.warning_amber_rounded;
      case ToastType.info:
        return Icons.info;
    }
  }
}
