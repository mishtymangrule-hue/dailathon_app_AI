import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/app_notification.dart';
import '../../../core/repositories/notification_repository.dart';
import '../../../core/services/notification_sync_service.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

class NotificationsBloc
    extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc({
    required NotificationRepository notificationRepository,
    required NotificationSyncService syncService,
  })  : _repo = notificationRepository,
        _syncService = syncService,
        super(const NotificationsLoading()) {
    on<NotificationsRefreshRequested>(_onRefresh);
    on<NotificationDismissed>(_onDismissed);
    on<NotificationActedOn>(_onActedOn);
    on<NotificationDelivered>(_onDelivered);
  }

  final NotificationRepository _repo;
  final NotificationSyncService _syncService;

  Future<void> _onRefresh(
    NotificationsRefreshRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(const NotificationsLoading());
    try {
      await _syncService.sync();
      final all = await _repo.getAll();
      final unread = await _repo.getUnreadCount();
      emit(NotificationsLoaded(notifications: all, unreadCount: unread));
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }

  Future<void> _onDismissed(
    NotificationDismissed event,
    Emitter<NotificationsState> emit,
  ) async {
    await _repo.updateStatus(event.notificationId, NotificationStatus.dismissed);
    add(const NotificationsRefreshRequested());
  }

  Future<void> _onActedOn(
    NotificationActedOn event,
    Emitter<NotificationsState> emit,
  ) async {
    await _repo.updateStatus(event.notificationId, NotificationStatus.acted);
    add(const NotificationsRefreshRequested());
  }

  Future<void> _onDelivered(
    NotificationDelivered event,
    Emitter<NotificationsState> emit,
  ) async {
    await _repo.updateStatus(
      event.notificationId,
      NotificationStatus.delivered,
      deliveredAt: DateTime.now(),
    );
    add(const NotificationsRefreshRequested());
  }
}
