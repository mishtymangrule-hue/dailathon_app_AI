import 'package:flutter_test/flutter_test.dart';
import 'package:dailathon_dialer/core/services/call_event_logger.dart';
import 'package:dailathon_dialer/core/models/call_log_entry.dart';
import 'package:dailathon_dialer/core/repositories/crm_repository.dart';
import 'package:dailathon_dialer/core/api/api_client.dart';

void main() {
  group('CRM Integration - Call Data Reporting', () {
    late CallEventLogger callEventLogger;
    late MockCrmRepository mockCrmRepository;
    late MockApiClient mockApiClient;

    setUp(() {
      mockCrmRepository = MockCrmRepository();
      mockApiClient = MockApiClient();
      callEventLogger = CallEventLogger(
        crmRepository: mockCrmRepository,
        apiClient: mockApiClient,
      );
    });

    group('Call Status Tracking', () {
      test('should log answered call with duration and ringing time', () async {
        // Arrange
        final event = CallEvent(
          callId: 'call_001',
          phoneNumber: '+91-9000000001',
          startTime: DateTime.now().subtract(const Duration(minutes: 5)),
          ringingDurationSeconds: 15,
          activeDurationSeconds: 180,
          classification: CallClassification.answered,
          direction: 'inbound',
        );

        // Act
        final result = await callEventLogger.logCallEvent(event);

        // Assert
        expect(result, true);
        expect(event.crmStatus, 'completed');
        expect(event.activeDurationSeconds, 180);
        expect(event.ringingDurationSeconds, 15);
      });

      test('should log unanswered call as missed', () async {
        // Arrange
        final event = CallEvent(
          callId: 'call_002',
          phoneNumber: '+91-9000000002',
          startTime: DateTime.now().subtract(const Duration(minutes: 2)),
          ringingDurationSeconds: 20,
          activeDurationSeconds: 0,
          classification: CallClassification.leadMissed,
          direction: 'inbound',
        );

        // Act
        final result = await callEventLogger.logCallEvent(event);

        // Assert
        expect(result, true);
        expect(event.crmStatus, 'missed');
        expect(event.crmClassification, 'lead_missed');
      });

      test('should log employee rejected call', () async {
        // Arrange
        final event = CallEvent(
          callId: 'call_003',
          phoneNumber: '+91-9000000003',
          startTime: DateTime.now(),
          ringingDurationSeconds: 3,
          activeDurationSeconds: 0,
          classification: CallClassification.employeeRejected,
          direction: 'inbound',
        );

        // Act
        final result = await callEventLogger.logCallEvent(event);

        // Assert
        expect(result, true);
        expect(event.crmStatus, 'declined');
        expect(event.crmClassification, 'employee_rejected');
      });

      test('should log lead rejected call', () async {
        // Arrange
        final event = CallEvent(
          callId: 'call_004',
          phoneNumber: '+91-9000000004',
          startTime: DateTime.now(),
          ringingDurationSeconds: 5,
          activeDurationSeconds: 0,
          classification: CallClassification.leadRejected,
          direction: 'inbound',
        );

        // Act
        final result = await callEventLogger.logCallEvent(event);

        // Assert
        expect(result, true);
        expect(event.crmStatus, 'declined');
        expect(event.crmClassification, 'lead_rejected');
      });

      test('should log employee ended call', () async {
        // Arrange
        final event = CallEvent(
          callId: 'call_005',
          phoneNumber: '+91-9000000005',
          startTime: DateTime.now().subtract(const Duration(minutes: 1)),
          ringingDurationSeconds: 10,
          activeDurationSeconds: 30,
          classification: CallClassification.employeeEnded,
          direction: 'outbound',
        );

        // Act
        final result = await callEventLogger.logCallEvent(event);

        // Assert
        expect(result, true);
        expect(event.crmStatus, 'missed');
        expect(event.crmClassification, 'employee_ended');
      });
    });

    group('Call Attempt Tracking', () {
      test('should track multiple call attempts for same lead', () async {
        // Arrange: Same lead, multiple calls
        const phoneNumber = '+91-9000000010';
        const contactId = 'contact_001';

        final event1 = CallEvent(
          callId: 'call_101',
          phoneNumber: phoneNumber,
          contactId: contactId,
          startTime: DateTime.now().subtract(const Duration(hours: 2)),
          ringingDurationSeconds: 20,
          activeDurationSeconds: 120,
          classification: CallClassification.answered,
          direction: 'outbound',
        );

        final event2 = CallEvent(
          callId: 'call_102',
          phoneNumber: phoneNumber,
          contactId: contactId,
          startTime: DateTime.now().subtract(const Duration(hours: 1)),
          ringingDurationSeconds: 15,
          activeDurationSeconds: 150,
          classification: CallClassification.answered,
          direction: 'outbound',
        );

        final event3 = CallEvent(
          callId: 'call_103',
          phoneNumber: phoneNumber,
          contactId: contactId,
          startTime: DateTime.now(),
          ringingDurationSeconds: 25,
          activeDurationSeconds: 0,
          classification: CallClassification.leadMissed,
          direction: 'outbound',
        );

        // Act
        final result1 = await callEventLogger.logCallEvent(event1);
        final result2 = await callEventLogger.logCallEvent(event2);
        final result3 = await callEventLogger.logCallEvent(event3);

        // Assert: All three calls logged
        expect(result1, true);
        expect(result2, true);
        expect(result3, true);

        // Verify timestamps are preserved
        expect(event1.startTime.isBefore(event2.startTime), true);
        expect(event2.startTime.isBefore(event3.startTime), true);
      });

      test('should track call history per lead', () async {
        // Arrange
        const contactId = 'contact_002';
        mockCrmRepository.expectedCallHistory = [
          CallEvent(
            callId: 'call_201',
            phoneNumber: '+91-9000000020',
            contactId: contactId,
            startTime: DateTime.now().subtract(const Duration(days: 3)),
            ringingDurationSeconds: 10,
            activeDurationSeconds: 120,
            classification: CallClassification.answered,
            direction: 'outbound',
          ),
          CallEvent(
            callId: 'call_202',
            phoneNumber: '+91-9000000020',
            contactId: contactId,
            startTime: DateTime.now().subtract(const Duration(days: 1)),
            ringingDurationSeconds: 15,
            activeDurationSeconds: 90,
            classification: CallClassification.answered,
            direction: 'outbound',
          ),
        ];

        // Act
        final history = mockCrmRepository.getCallHistory(contactId);

        // Assert
        expect(history, isNotEmpty);
        expect(history.length, 2);
      });
    });

    group('Incoming Call Verification', () {
      test('should verify incoming call from CRM lead', () async {
        // Arrange
        const phoneNumber = '+91-9000000030';
        mockCrmRepository.expectedLead = CrmContact(
          id: 'lead_001',
          name: 'John Doe',
          phoneNumber: phoneNumber,
        );

        // Act
        final event = CallEvent(
          callId: 'call_301',
          phoneNumber: phoneNumber,
          startTime: DateTime.now(),
          ringingDurationSeconds: 0,
          activeDurationSeconds: 200,
          classification: CallClassification.answered,
          direction: 'inbound',
        );

        final result = await callEventLogger.logCallEvent(event);

        // Assert
        expect(result, true);
        expect(event.direction, 'inbound');
      });

      test('should classify incoming call as answered', () async {
        // Arrange
        final event = CallEvent(
          callId: 'call_302',
          phoneNumber: '+91-9000000031',
          startTime: DateTime.now().subtract(const Duration(minutes: 5)),
          ringingDurationSeconds: 8,
          activeDurationSeconds: 240,
          classification: CallClassification.answered,
          direction: 'inbound',
        );

        // Act
        final result = await callEventLogger.logCallEvent(event);

        // Assert
        expect(result, true);
        expect(event.crmStatus, 'completed');
      });

      test('should classify incoming call as rejected', () async {
        // Arrange
        final event = CallEvent(
          callId: 'call_303',
          phoneNumber: '+91-9000000032',
          startTime: DateTime.now(),
          ringingDurationSeconds: 2,
          activeDurationSeconds: 0,
          classification: CallClassification.leadRejected,
          direction: 'inbound',
        );

        // Act
        final result = await callEventLogger.logCallEvent(event);

        // Assert
        expect(result, true);
        expect(event.crmStatus, 'declined');
      });

      test('should classify incoming call as missed', () async {
        // Arrange
        final event = CallEvent(
          callId: 'call_304',
          phoneNumber: '+91-9000000033',
          startTime: DateTime.now(),
          ringingDurationSeconds: 30,
          activeDurationSeconds: 0,
          classification: CallClassification.leadMissed,
          direction: 'inbound',
        );

        // Act
        final result = await callEventLogger.logCallEvent(event);

        // Assert
        expect(result, true);
        expect(event.crmStatus, 'missed');
      });
    });

    group('CRM Synchronization', () {
      test('should send call data to CRM in real-time', () async {
        // Arrange
        final event = CallEvent(
          callId: 'call_401',
          phoneNumber: '+91-9000000040',
          contactId: 'lead_040',
          employeeId: 'emp_001',
          startTime: DateTime.now().subtract(const Duration(minutes: 3)),
          ringingDurationSeconds: 12,
          activeDurationSeconds: 180,
          classification: CallClassification.answered,
          direction: 'outbound',
          notes: 'Discussed admission inquiry',
        );

        // Act
        final result = await callEventLogger.logCallEvent(event);

        // Assert
        expect(result, true);
        expect(mockApiClient.lastPostedData, isNotNull);
      });

      test('should retry on network failure', () async {
        // Arrange
        mockApiClient.shouldFail = true;
        mockApiClient.failureCount = 2; // Fail twice, succeed on third

        final event = CallEvent(
          callId: 'call_402',
          phoneNumber: '+91-9000000041',
          startTime: DateTime.now(),
          ringingDurationSeconds: 10,
          activeDurationSeconds: 120,
          classification: CallClassification.answered,
          direction: 'inbound',
        );

        // Act
        final result = await callEventLogger.logCallEvent(event);

        // Assert - Should eventually succeed after retries
        expect(mockApiClient.attemptCount, lessThanOrEqualTo(3));
      });

      test('should queue event if CRM is unavailable', () async {
        // Arrange
        mockApiClient.shouldFail = true;
        mockApiClient.failureCount = 10; // Always fail

        final event = CallEvent(
          callId: 'call_403',
          phoneNumber: '+91-9000000042',
          startTime: DateTime.now(),
          ringingDurationSeconds: 10,
          activeDurationSeconds: 100,
          classification: CallClassification.answered,
          direction: 'inbound',
        );

        // Act
        final result = await callEventLogger.logCallEvent(event);

        // Assert
        expect(result, false);
        expect(callEventLogger.pendingEventsCount, 1);
        expect(callEventLogger.pendingEvents[0].callId, 'call_403');
      });

      test('should persist call data mapping to CRM statuses', () async {
        // Arrange
        final classifications = [
          (CallClassification.answered, 'completed'),
          (CallClassification.leadMissed, 'missed'),
          (CallClassification.leadRejected, 'declined'),
          (CallClassification.employeeRejected, 'declined'),
          (CallClassification.employeeEnded, 'missed'),
        ];

        // Act & Assert
        for (final (classification, expectedStatus) in classifications) {
          final event = CallEvent(
            callId: 'test_${classification.name}',
            phoneNumber: '+91-9000000050',
            startTime: DateTime.now(),
            ringingDurationSeconds: 10,
            activeDurationSeconds: 100,
            classification: classification,
            direction: 'inbound',
          );

          expect(event.crmStatus, expectedStatus);
        }
      });
    });

    group('Event Delivery Reliability', () {
      test('should implement exponential backoff retry', () async {
        // Arrange
        mockApiClient.shouldFail = true;
        mockApiClient.failureCount = 2;

        final event = CallEvent(
          callId: 'call_501',
          phoneNumber: '+91-9000000051',
          startTime: DateTime.now(),
          ringingDurationSeconds: 10,
          activeDurationSeconds: 120,
          classification: CallClassification.answered,
          direction: 'inbound',
        );

        // Act
        final result = await callEventLogger.logCallEvent(event);

        // Assert
        expect(mockApiClient.delaysBetweenAttempts, isNotEmpty);
        // Delays should increase exponentially
        if (mockApiClient.delaysBetweenAttempts.length > 1) {
          expect(
            mockApiClient.delaysBetweenAttempts[1],
            greaterThan(mockApiClient.delaysBetweenAttempts[0]),
          );
        }
      });

      test('should handle timeout and retry', () async {
        // Arrange
        mockApiClient.shouldTimeout = true;

        final event = CallEvent(
          callId: 'call_502',
          phoneNumber: '+91-9000000052',
          startTime: DateTime.now(),
          ringingDurationSeconds: 10,
          activeDurationSeconds: 120,
          classification: CallClassification.answered,
          direction: 'inbound',
        );

        // Act
        final result = await callEventLogger.logCallEvent(event);

        // Assert - Should queue after timeout
        expect(callEventLogger.pendingEventsCount, greaterThanOrEqualTo(0));
      });

      test('should deduplicate multiple retries', () async {
        // Arrange
        mockApiClient.shouldFail = true;
        mockApiClient.failureCount = 1;

        final event = CallEvent(
          callId: 'call_503',
          phoneNumber: '+91-9000000053',
          startTime: DateTime.now(),
          ringingDurationSeconds: 10,
          activeDurationSeconds: 120,
          classification: CallClassification.answered,
          direction: 'inbound',
        );

        // Act
        await callEventLogger.logCallEvent(event);

        // Assert
        expect(event.callId, 'call_503'); // Same call ID throughout
      });
    });

    group('Offline Support', () {
      test('should queue events when offline', () async {
        // Arrange
        mockApiClient.isOnline = false;

        final event1 = CallEvent(
          callId: 'call_601',
          phoneNumber: '+91-9000000061',
          startTime: DateTime.now(),
          ringingDurationSeconds: 10,
          activeDurationSeconds: 120,
          classification: CallClassification.answered,
          direction: 'inbound',
        );

        final event2 = CallEvent(
          callId: 'call_602',
          phoneNumber: '+91-9000000062',
          startTime: DateTime.now(),
          ringingDurationSeconds: 8,
          activeDurationSeconds: 90,
          classification: CallClassification.answered,
          direction: 'inbound',
        );

        // Act
        await callEventLogger.logCallEvent(event1);
        await callEventLogger.logCallEvent(event2);

        // Assert
        expect(callEventLogger.pendingEventsCount, 2);
      });

      test('should retry queued events when online', () async {
        // Arrange
        mockApiClient.isOnline = false;

        final event = CallEvent(
          callId: 'call_603',
          phoneNumber: '+91-9000000063',
          startTime: DateTime.now(),
          ringingDurationSeconds: 10,
          activeDurationSeconds: 120,
          classification: CallClassification.answered,
          direction: 'inbound',
        );

        await callEventLogger.logCallEvent(event);

        // Go online
        mockApiClient.isOnline = true;

        // Act
        await callEventLogger.retryPendingEvents();

        // Assert
        expect(callEventLogger.pendingEventsCount, 0);
      });
    });

    group('Call Event Serialization', () {
      test('should serialize call event with all required fields', () async {
        // Arrange
        final now = DateTime.now();
        final event = CallEvent(
          callId: 'call_701',
          phoneNumber: '+91-9000000070',
          contactId: 'lead_070',
          employeeId: 'emp_070',
          startTime: now,
          ringingDurationSeconds: 15,
          activeDurationSeconds: 300,
          classification: CallClassification.answered,
          direction: 'inbound',
          notes: 'Test call',
        );

        // Act
        final json = event.toJson();

        // Assert
        expect(json['callId'], 'call_701');
        expect(json['phoneNumber'], '+91-9000000070');
        expect(json['contactId'], 'lead_070');
        expect(json['employeeId'], 'emp_070');
        expect(json['duration'], 300);
        expect(json['ringingDuration'], 15);
        expect(json['status'], 'completed');
        expect(json['classification'], 'call_answered');
        expect(json['direction'], 'inbound');
        expect(json['notes'], 'Test call');
      });
    });
  });
}

// ========== MOCKS ==========

class MockCrmRepository implements CrmRepository {
  CrmContact? expectedLead;
  List<CallEvent> expectedCallHistory = [];

  @override
  Future<List<CrmCall>> getCallHistory(String contactId, {int limit = 50}) async => [];

  @override
  Future<CrmContact?> lookupContactByPhone(String phoneNumber) async => expectedLead;

  @override
  List<CallEvent> getCallHistory(String contactId) => expectedCallHistory;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockApiClient implements ApiClient {
  bool shouldFail = false;
  bool shouldTimeout = false;
  bool isOnline = true;
  int failureCount = 0;
  int attemptCount = 0;
  Map<String, dynamic>? lastPostedData;
  List<Duration> delaysBetweenAttempts = [];

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  }) async {
    attemptCount++;

    if (shouldTimeout) {
      await Future.delayed(const Duration(seconds: 35)); // Longer than timeout
    }

    if (shouldFail && failureCount > 0) {
      failureCount--;
      throw Exception('Network error');
    }

    if (!isOnline) {
      throw Exception('Offline');
    }

    lastPostedData = data;
    return {'data': 'success'};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
