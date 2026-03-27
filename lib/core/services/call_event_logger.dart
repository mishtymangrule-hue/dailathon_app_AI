import 'package:dailathon_dialer/core/repositories/crm_repository.dart';
import 'package:dailathon_dialer/core/models/call_log_entry.dart';
import 'package:dailathon_dialer/core/api/api_client.dart';

/// Call classification for CRM integration
enum CallClassification {
  answered,
  employeeRejected,
  employeeEnded,
  leadRejected,
  leadMissed,
}

/// Extended call event for CRM reporting
class CallEvent {

  CallEvent({
    required this.callId,
    required this.phoneNumber,
    required this.startTime, required this.ringingDurationSeconds, required this.activeDurationSeconds, required this.classification, required this.direction, this.contactId,
    this.employeeId,
    this.endTime,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  final String callId;
  final String phoneNumber;
  final String? contactId;
  final String? employeeId;
  final DateTime startTime;
  final DateTime? endTime;
  final int ringingDurationSeconds;
  final int activeDurationSeconds;
  final CallClassification classification;
  final String direction; // 'inbound' or 'outbound'
  final String? notes;
  final DateTime createdAt;

  /// Convert classification to CRM status
  String get crmStatus {
    switch (classification) {
      case CallClassification.answered:
        return 'completed';
      case CallClassification.employeeRejected:
      case CallClassification.leadRejected:
        return 'declined';
      case CallClassification.employeeEnded:
      case CallClassification.leadMissed:
        return 'missed';
    }
  }

  /// Convert classification to CRM description
  String get crmClassification {
    switch (classification) {
      case CallClassification.answered:
        return 'call_answered';
      case CallClassification.employeeRejected:
        return 'employee_rejected';
      case CallClassification.employeeEnded:
        return 'employee_ended';
      case CallClassification.leadRejected:
        return 'lead_rejected';
      case CallClassification.leadMissed:
        return 'lead_missed';
    }
  }

  /// Serialize to JSON for API
  Map<String, dynamic> toJson() => {
        'callId': callId,
        'phoneNumber': phoneNumber,
        'contactId': contactId,
        'employeeId': employeeId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'ringingDurationSeconds': ringingDurationSeconds,
        'activeDurationSeconds': activeDurationSeconds,
        'classification': crmClassification,
        'status': crmStatus,
        'direction': direction,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };
}

/// Service for logging call events to CRM with retry logic
class CallEventLogger {

  CallEventLogger({
    required CrmRepository crmRepository,
    required ApiClient apiClient,
  })  : _crmRepository = crmRepository,
        _apiClient = apiClient;
  final CrmRepository _crmRepository;
  final ApiClient _apiClient;

  // Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 5);
  static const Duration networkTimeout = Duration(seconds: 30);

  // Pending events queue (for offline support)
  final List<CallEvent> _pendingEvents = [];

  /// Log a call with full event details and retry logic
  Future<bool> logCallEvent(CallEvent event) async {
    try {
      // Step 1: Verify lead exists in CRM if contactId not provided
      var contactId = event.contactId;
      if (contactId == null) {
        contactId = await _verifyAndGetLeadId(event.phoneNumber);
        if (contactId == null) {
          // Still log the event even if lead not found
        }
      }

      // Step 2: Prepare call data with proper CRM mapping
      final callData = {
        'callId': event.callId,
        'phoneNumber': event.phoneNumber,
        'contactId': contactId,
        'employeeId': event.employeeId,
        'callTime': event.startTime.toIso8601String(),
        'duration': event.activeDurationSeconds,
        'ringingDuration': event.ringingDurationSeconds,
        'direction': event.direction,
        'status': event.crmStatus,
        'classification': event.crmClassification,
        'notes': event.notes,
        'timestamp': event.createdAt.toIso8601String(),
      };

      // Step 3: Send to CRM with retry logic
      final success = await _sendToCrmWithRetry(callData);

      if (success) {
        return true;
      } else {
        // Queue for later retry
        _pendingEvents.add(event);
        return false;
      }
    } catch (e) {
      // Queue for later retry
      _pendingEvents.add(event);
      return false;
    }
  }

  /// Verify lead exists in CRM by phone number
  Future<String?> _verifyAndGetLeadId(String phoneNumber) async {
    try {
      final contact = await _crmRepository.lookupContactByPhone(phoneNumber);
      if (contact != null) {
        return contact.id;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Send call data to CRM with exponential backoff retry
  Future<bool> _sendToCrmWithRetry(Map<String, dynamic> callData) async {
    var attempt = 0;
    var delay = retryDelay;

    while (attempt < maxRetries) {
      try {
        await _apiClient
            .post(
              '/calls/log',
              data: callData,
            )
            .timeout(networkTimeout);

        return true;
      } catch (e) {
        attempt++;

        if (attempt < maxRetries) {
          await Future.delayed(delay);
          delay = Duration(milliseconds: delay.inMilliseconds * 2); // Exponential backoff
        }
      }
    }

    return false;
  }

  /// Log call from CallLogEntry
  Future<bool> logCallFromEntry(CallLogEntry entry, {String? employeeId}) async {
    final classification = _classifyCall(entry);
    final ringingDuration = _calculateRingingDuration(entry);

    final event = CallEvent(
      callId: entry.id,
      phoneNumber: entry.phoneNumber,
      employeeId: employeeId,
      startTime: DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
      ringingDurationSeconds: ringingDuration,
      activeDurationSeconds: entry.duration,
      classification: classification,
      direction: entry.isIncoming ? 'inbound' : 'outbound',
    );

    return logCallEvent(event);
  }

  /// Classify call based on CallLogEntry properties
  CallClassification _classifyCall(CallLogEntry entry) {
    if (entry.isMissed) {
      // Determine if missed because lead didn't answer or was rejected
      // This would need additional context from the call state
      return CallClassification.leadMissed;
    } else if (entry.duration > 0) {
      return CallClassification.answered;
    } else {
      // Call was initiated but not answered
      // Default to outbound ended if outgoing, inbound missed if incoming
      return entry.isIncoming ? CallClassification.leadMissed : CallClassification.employeeEnded;
    }
  }

  /// Calculate ringing duration (estimate based on total duration)
  int _calculateRingingDuration(CallLogEntry entry) {
    // In real implementation, this would come from separate tracking
    // For now, estimate as 20% of total duration  or 0 if answered quickly
    if (entry.duration > 10) {
      return (entry.duration * 0.15).toInt();
    }
    return 0;
  }

  /// Retry sending pending events
  Future<void> retryPendingEvents() async {
    final eventsToRetry = List<CallEvent>.from(_pendingEvents);
    _pendingEvents.clear();

    for (final event in eventsToRetry) {
      await logCallEvent(event);
    }
  }

  /// Get pending events count
  int get pendingEventsCount => _pendingEvents.length;

  /// Get all pending events
  List<CallEvent> get pendingEvents => List.unmodifiable(_pendingEvents);

  /// Clear pending events
  void clearPendingEvents() {
    _pendingEvents.clear();
  }
}
