import 'dart:developer' as developer;

import 'package:uuid/uuid.dart';

import '../models/call_event_payload.dart';
import '../repositories/crm_repository.dart';
import 'call_event_queue.dart';

/// Builds a [CallEventPayload] from a raw call event map, enqueues it, and
/// attempts immediate delivery; if delivery fails the queue handles retries.
class CrmReportingService {
  CrmReportingService({
    required CrmRepository crmRepository,
    required CallEventQueue eventQueue,
  })  : _crm = crmRepository,
        _queue = eventQueue;

  final CrmRepository _crm;
  final CallEventQueue _queue;
  final _uuid = const Uuid();

  /// Called when a call ends.
  ///
  /// [rawEvent] is the raw call event map from the platform channel; it must
  /// contain at least `callId`, `phoneNumber`, `direction`, `startedAt`,
  /// `ringingDurationSeconds`, `activeDurationSeconds`.
  Future<void> reportCallEnd(Map<String, dynamic> rawEvent) async {
    final payload = await _buildPayload(rawEvent);
    if (payload == null) return;

    await _queue.enqueue(payload);
    // Attempt immediate flush
    await _flush();
  }

  /// Flush all queued events.  Called by the WorkManager worker on a schedule.
  Future<void> flush() => _flush();

  Future<void> _flush() async {
    await _queue.flushAll((payload) => _crm.reportCallEvent(payload.toJson()));
  }

  Future<CallEventPayload?> _buildPayload(
      Map<String, dynamic> raw) async {
    try {
      final phoneNumber = raw['phoneNumber'] as String? ?? '';
      if (phoneNumber.isEmpty) return null;

      final callId = raw['callId'] as String? ?? _uuid.v4();
      final direction = raw['direction'] as String? ?? 'outbound';
      final startedAt = raw['startedAt'] is DateTime
          ? raw['startedAt'] as DateTime
          : DateTime.tryParse(raw['startedAt'] as String? ?? '') ??
              DateTime.now();

      // Determine status from raw event
      final statusStr = raw['status'] as String?;
      final CallStatus status;
      final UnansweredReason? unansweredReason;
      switch (statusStr) {
        case 'completed':
          status = CallStatus.answered;
          unansweredReason = null;
          break;
        case 'declined':
          status = CallStatus.rejected;
          unansweredReason = UnansweredReason.declined;
          break;
        case 'missed':
          status = CallStatus.unanswered;
          unansweredReason = UnansweredReason.noAnswer;
          break;
        default:
          final active = raw['activeDurationSeconds'] as int? ?? 0;
          status = active > 0 ? CallStatus.answered : CallStatus.unanswered;
          unansweredReason =
              active > 0 ? null : UnansweredReason.noAnswer;
      }

      // Lookup CRM contact + attempt count
      var contactId = raw['contactId'] as String?;
      var attemptCount = 0;
      if (contactId != null) {
        attemptCount = await _crm.getAttemptCount(contactId);
      }

      return CallEventPayload(
        eventId: _uuid.v4(),
        callId: callId,
        phoneNumber: phoneNumber,
        direction: direction,
        status: status,
        unansweredReason: unansweredReason,
        ringingDurationSeconds:
            raw['ringingDurationSeconds'] as int? ?? 0,
        activeDurationSeconds:
            raw['activeDurationSeconds'] as int? ?? 0,
        startedAt: startedAt,
        endedAt: raw['endedAt'] is DateTime
            ? raw['endedAt'] as DateTime
            : DateTime.tryParse(raw['endedAt'] as String? ?? ''),
        contactId: contactId,
        employeeId: raw['employeeId'] as String?,
        simSlot: raw['simSlot'] as int?,
        attemptCount: attemptCount,
      );
    } catch (e) {
      developer.log('CrmReportingService: failed to build payload — $e',
          level: 900);
      return null;
    }
  }
}
