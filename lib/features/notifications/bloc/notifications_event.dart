part of 'notifications_bloc.dart';

abstract class NotificationsEvent {
  const NotificationsEvent();
}

class NotificationsRefreshRequested extends NotificationsEvent {
  const NotificationsRefreshRequested();
}

class NotificationDismissed extends NotificationsEvent {
  const NotificationDismissed(this.notificationId);
  final String notificationId;
}

class NotificationActedOn extends NotificationsEvent {
  const NotificationActedOn(this.notificationId);
  final String notificationId;
}

class NotificationDelivered extends NotificationsEvent {
  const NotificationDelivered(this.notificationId);
  final String notificationId;
}
