import 'package:flutter/services.dart';

import '../models/call_log_entry.dart' as call_log;
import '../models/contact.dart';
import '../models/sim_info.dart';

class ContactsMethodChannel {
  static const _channel = MethodChannel('com.mangrule.dailathon/contacts');

  Future<List<call_log.CallLogEntry>> getCallLog({int limit = 500}) async {
    final result = await _channel.invokeMethod('getCallLog', {'limit': limit});
    return (result as List)
        .map((e) => call_log.CallLogEntry.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<Contact>> getContacts() async {
    final result = await _channel.invokeMethod('getContacts');
    return (result as List)
        .map((e) => Contact.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<Contact>> searchContacts(String query) async {
    final result = await _channel.invokeMethod('searchContacts', {'query': query});
    return (result as List)
        .map((e) => Contact.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Contact?> lookupNumber(String number) async {
    final result = await _channel.invokeMethod('lookupNumber', {'number': number});
    if (result == null) return null;
    return Contact.fromMap(Map<String, dynamic>.from(result as Map));
  }

  Future<List<String>> getBlockedNumbers() async {
    final result = await _channel.invokeMethod('getBlockedNumbers');
    return List<String>.from(result);
  }

  Future<void> blockNumber(String number) =>
      _channel.invokeMethod('blockNumber', {'number': number});

  Future<void> unblockNumber(String number) =>
      _channel.invokeMethod('unblockNumber', {'number': number});

  Future<void> deleteCallLogEntry(String entryId) =>
      _channel.invokeMethod('deleteCallLogEntry', {'entryId': entryId});

  Future<void> clearCallLog() =>
      _channel.invokeMethod('clearCallLog');

  Future<List<SimInfo>> getSimSlots() async {
    final result = await _channel.invokeMethod('getSimSlots');
    return (result as List)
        .map((e) => SimInfo.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
