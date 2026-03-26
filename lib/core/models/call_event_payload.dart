import 'package:equatable/equatable.dart';

enum CallStatus {
  answered,
  unanswered,
  rejected,
}

enum UnansweredReason {
  noAnswer,
  busy,
  declined,
  unavailable,
}

class CallEventPayload extends Equatable {
  const CallEventPayload({
    required this.eventId,
    required this.callId,
    required this.phoneNumber,
    required this.direction,
    required this.status,
    this.unansweredReason,
    required this.ringingDurationSeconds,
    required this.activeDurationSeconds,
    required this.startedAt,
    this.endedAt,
    this.contactId,
    this.employeeId,
    this.simSlot,
    this.attemptCount = 0,
  });

  factory CallEventPayload.fromJson(Map<String, dynamic> json) =>
      CallEventPayload(
        eventId: json['eventId'] as String,
        callId: json['callId'] as String,
        phoneNumber: json['phoneNumber'] as String,
        direction: json['direction'] as String,
        status: CallStatus.values.byName(json['status'] as String),
        unansweredReason: json['unansweredReason'] != null
            ? UnansweredReason.values
                .byName(json['unansweredReason'] as String)
            : null,
        ringingDurationSeconds:
            json['ringingDurationSeconds'] as int? ?? 0,
        activeDurationSeconds:
            json['activeDurationSeconds'] as int? ?? 0,
        startedAt: DateTime.parse(json['startedAt'] as String),
        endedAt: json['endedAt'] != null
            ? DateTime.parse(json['endedAt'] as String)
            : null,
        contactId: json['contactId'] as String?,
        employeeId: json['employeeId'] as String?,
        simSlot: json['simSlot'] as int?,
        attemptCount: json['attemptCount'] as int? ?? 0,
      );

  final String eventId;
  final String callId;
  final String phoneNumber;
  final String direction; // 'inbound' | 'outbound'
  final CallStatus status;
  final UnansweredReason? unansweredReason;
  final int ringingDurationSeconds;
  final int activeDurationSeconds;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? contactId;
  final String? employeeId;
  final int? simSlot;
  final int attemptCount;

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'callId': callId,
        'phoneNumber': phoneNumber,
        'direction': direction,
        'status': status.name,
        if (unansweredReason != null)
          'unansweredReason': unansweredReason!.name,
        'ringingDurationSeconds': ringingDurationSeconds,
        'activeDurationSeconds': activeDurationSeconds,
        'startedAt': startedAt.toIso8601String(),
        if (endedAt != null) 'endedAt': endedAt!.toIso8601String(),
        if (contactId != null) 'contactId': contactId,
        if (employeeId != null) 'employeeId': employeeId,
        if (simSlot != null) 'simSlot': simSlot,
        'attemptCount': attemptCount,
      };

  @override
  List<Object?> get props => [eventId, callId, status, startedAt];
}
