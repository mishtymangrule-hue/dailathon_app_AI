import 'dart:developer' as developer;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/app_notification.dart';
import '../repositories/crm_repository.dart';
import '../repositories/notification_repository.dart';

/// Syncs scheduled notifications from the CRM and persists them locally.
///
/// Call [sync] periodically (or on app resume) to keep the local store fresh.
class NotificationSyncService {
  NotificationSyncService({
    required CrmRepository crmRepository,
    required NotificationRepository notificationRepository,
    FlutterSecureStorage? secureStorage,
  })  : _crm = crmRepository,
        _repo = notificationRepository,
        _storage = secureStorage ?? const FlutterSecureStorage();

  final CrmRepository _crm;
  final NotificationRepository _repo;
  final FlutterSecureStorage _storage;

  static const _employeeIdKey = 'employee_id';

  /// Syncs notifications from CRM into the local SQLite store.
  ///
  /// Returns the list of newly-added/updated notifications after sync.
  Future<List<AppNotification>> sync() async {
    try {
      final employeeId = await _storage.read(key: _employeeIdKey) ?? '';
      if (employeeId.isEmpty) {
        developer.log('NotificationSyncService: no employee id stored, skip sync');
        return [];
      }

      final raw = await _crm.getScheduledNotifications(employeeId);
      final notifications = raw.map((json) => AppNotification.fromJson(json)).toList();

      await _repo.upsertAll(notifications);
      // Prune items older than 30 days
      await _repo.deleteOlderThan(const Duration(days: 30));

      developer.log('NotificationSyncService: synced ${notifications.length} notifications');
      return notifications;
    } catch (e) {
      developer.log('NotificationSyncService: sync failed — $e', level: 900);
      return [];
    }
  }
}
