import 'package:dailathon_dialer/core/channels/contacts_method_channel.dart';
import 'package:dailathon_dialer/core/models/call_log_entry.dart';

/// Repository for accessing call log data.
/// 
/// Provides methods to query, filter, and manage call history.
/// Delegates to native Android code through ContactsMethodChannel.
class CallLogRepository {
  CallLogRepository({ContactsMethodChannel? contactsMethodChannel})
      : _contactsMethodChannel = contactsMethodChannel ?? ContactsMethodChannel();

  final ContactsMethodChannel _contactsMethodChannel;

  /// Get all call log entries up to [limit].
  /// 
  /// [limit]: Maximum number of entries to retrieve (default 500)
  /// Returns a list of CallLogEntry sorted by newest first
  Future<List<CallLogEntry>> getCallLog({int limit = 500}) async {
    try {
      final entries = await _contactsMethodChannel.getCallLog(limit: limit);
      return entries;
    } catch (e) {
      rethrow;
    }
  }

  /// Get calls with a specific phone number.
  /// 
  /// [phoneNumber]: Phone number to filter by
  /// Returns matching call log entries
  Future<List<CallLogEntry>> getCallsWithNumber(String phoneNumber) async {
    try {
      final allEntries = await getCallLog(limit: 1000);
      return allEntries
          .where((entry) =>
              entry.phoneNumber.contains(phoneNumber) ||
              phoneNumber.contains(entry.phoneNumber))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get incoming calls only.
  /// 
  /// [limit]: Maximum number of entries to retrieve (default 500)
  /// Returns incoming call entries
  Future<List<CallLogEntry>> getIncomingCalls({int limit = 500}) async {
    try {
      final allEntries = await getCallLog(limit: limit);
      return allEntries.where((entry) => entry.isIncoming).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get outgoing calls only.
  /// 
  /// [limit]: Maximum number of entries to retrieve (default 500)
  /// Returns outgoing call entries
  Future<List<CallLogEntry>> getOutgoingCalls({int limit = 500}) async {
    try {
      final allEntries = await getCallLog(limit: limit);
      return allEntries.where((entry) => entry.isOutgoing).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get missed calls only.
  /// 
  /// [limit]: Maximum number of entries to retrieve (default 500)
  /// Returns missed call entries (type = 3)
  Future<List<CallLogEntry>> getMissedCalls({int limit = 500}) async {
    try {
      final allEntries = await getCallLog(limit: limit);
      return allEntries.where((entry) => entry.isMissed).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a specific call log entry.
  /// 
  /// [entryId]: ID of the entry to delete
  /// Note: This operation cannot be undone
  Future<void> deleteEntry(String entryId) async {
    try {
      await _contactsMethodChannel.deleteCallLogEntry(entryId);
    } catch (e) {
      rethrow;
    }
  }

  /// Clear all call log entries.
  /// 
  /// Warning: This operation cannot be undone and will delete entire call history
  Future<void> clearCallLog() async {
    try {
      await _contactsMethodChannel.clearCallLog();
    } catch (e) {
      rethrow;
    }
  }

  /// Get call log entries for a specific date range.
  /// 
  /// [startTime]: Start of date range (milliseconds since epoch)
  /// [endTime]: End of date range (milliseconds since epoch)
  /// Returns call entries within the specified range
  Future<List<CallLogEntry>> getCallsInDateRange({
    required int startTime,
    required int endTime,
  }) async {
    try {
      final allEntries = await getCallLog(limit: 5000);
      return allEntries
          .where((entry) =>
              entry.timestamp >= startTime && entry.timestamp <= endTime)
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get most recent call entries.
  /// 
  /// [count]: Number of recent entries to retrieve (default 10)
  /// Returns the most recent N call entries
  Future<List<CallLogEntry>> getRecentCalls({int count = 10}) async {
    try {
      final entries = await getCallLog(limit: count);
      return entries.take(count).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get total duration of all calls with a specific number.
  /// 
  /// [phoneNumber]: Phone number to calculate duration for
  /// Returns total duration in seconds
  Future<int> getTotalDurationWithNumber(String phoneNumber) async {
    try {
      final calls = await getCallsWithNumber(phoneNumber);
      return calls.fold<int>(0, (sum, call) => sum + call.duration);
    } catch (e) {
      rethrow;
    }
  }

  /// Get call count statistics.
  /// 
  /// Returns a map with counts of incoming, outgoing, and missed calls
  Future<Map<String, int>> getCallStatistics() async {
    try {
      final allEntries = await getCallLog(limit: 5000);
      return {
        'incoming': allEntries.where((e) => e.isIncoming).length,
        'outgoing': allEntries.where((e) => e.isOutgoing).length,
        'missed': allEntries.where((e) => e.isMissed).length,
        'total': allEntries.length,
      };
    } catch (e) {
      rethrow;
    }
  }
}
