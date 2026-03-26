import 'package:equatable/equatable.dart';

enum NotificationType { followUpCall, pendingCall, plannedVisit }

enum NotificationStatus { pending, delivered, dismissed, acted }

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.scheduledAt,
    this.deliveredAt,
    this.status = NotificationStatus.pending,
    this.studentId,
    this.phoneNumber,
    this.contactName,
    this.metadata = const {},
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        type: NotificationType.values.byName(json['type'] as String),
        title: json['title'] as String,
        body: json['body'] as String,
        scheduledAt: DateTime.parse(json['scheduledAt'] as String),
        deliveredAt: json['deliveredAt'] != null
            ? DateTime.parse(json['deliveredAt'] as String)
            : null,
        status: NotificationStatus.values.byName(
            (json['status'] as String? ?? 'pending')),
        studentId: json['studentId'] as String?,
        phoneNumber: json['phoneNumber'] as String?,
        contactName: json['contactName'] as String?,
        metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      );

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime scheduledAt;
  final DateTime? deliveredAt;
  final NotificationStatus status;
  final String? studentId;
  final String? phoneNumber;
  final String? contactName;
  final Map<String, dynamic> metadata;

  AppNotification copyWith({
    NotificationStatus? status,
    DateTime? deliveredAt,
  }) =>
      AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        scheduledAt: scheduledAt,
        deliveredAt: deliveredAt ?? this.deliveredAt,
        status: status ?? this.status,
        studentId: studentId,
        phoneNumber: phoneNumber,
        contactName: contactName,
        metadata: metadata,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'body': body,
        'scheduledAt': scheduledAt.toIso8601String(),
        'deliveredAt': deliveredAt?.toIso8601String(),
        'status': status.name,
        'studentId': studentId,
        'phoneNumber': phoneNumber,
        'contactName': contactName,
        'metadata': metadata,
      };

  @override
  List<Object?> get props => [id, type, title, body, scheduledAt, status];
}
