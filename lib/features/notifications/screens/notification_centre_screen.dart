import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/models/app_notification.dart';
import '../bloc/notifications_bloc.dart';

class NotificationCentreScreen extends StatelessWidget {
  const NotificationCentreScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () => context
                  .read<NotificationsBloc>()
                  .add(const NotificationsRefreshRequested()),
            ),
          ],
        ),
        body: BlocBuilder<NotificationsBloc, NotificationsState>(
          builder: (context, state) {
            if (state is NotificationsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is NotificationsError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Error: ${state.message}'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => context
                          .read<NotificationsBloc>()
                          .add(const NotificationsRefreshRequested()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            if (state is NotificationsLoaded) {
              if (state.notifications.isEmpty) {
                return const Center(child: Text('No notifications'));
              }
              return ListView.builder(
                itemCount: state.notifications.length,
                itemBuilder: (ctx, i) =>
                    _NotificationTile(notification: state.notifications[i]),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      );
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  IconData _icon() {
    switch (notification.type) {
      case NotificationType.followUpCall:
        return Icons.call;
      case NotificationType.pendingCall:
        return Icons.phone_missed;
      case NotificationType.plannedVisit:
        return Icons.event;
    }
  }

  Color _iconColor(BuildContext context) {
    switch (notification.status) {
      case NotificationStatus.pending:
        return Theme.of(context).colorScheme.primary;
      case NotificationStatus.delivered:
        return Colors.orange;
      case NotificationStatus.dismissed:
      case NotificationStatus.acted:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<NotificationsBloc>();
    final isDone = notification.status == NotificationStatus.dismissed ||
        notification.status == NotificationStatus.acted;

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) =>
          bloc.add(NotificationDismissed(notification.id)),
      child: ListTile(
        leading: Icon(_icon(), color: _iconColor(context)),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
                isDone ? FontWeight.normal : FontWeight.bold,
            color: isDone
                ? Theme.of(context).disabledColor
                : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 2),
            Text(
              DateFormat('MMM d, h:mm a')
                  .format(notification.scheduledAt.toLocal()),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        isThreeLine: true,
        trailing: isDone
            ? null
            : IconButton(
                icon: const Icon(Icons.check_circle_outline),
                tooltip: 'Mark done',
                onPressed: () =>
                    bloc.add(NotificationActedOn(notification.id)),
              ),
      ),
    );
  }
}
