import 'dart:convert';
import 'dart:developer' as developer;

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/call_event_payload.dart';

/// Persistent SQLite queue for CRM call event payloads.
///
/// Payloads are enqueued immediately on call end.  A periodic flush
/// (triggered by [CrmReportingService] or the Android WorkManager worker)
/// attempts delivery, retrying with exponential back-off.
class CallEventQueue {
  CallEventQueue._();

  static final CallEventQueue instance = CallEventQueue._();

  Database? _db;

  Future<Database> get _database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'crm_event_queue.db'),
      version: 1,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE crm_event_queue (
          eventId TEXT PRIMARY KEY,
          payload TEXT NOT NULL,
          createdAt INTEGER NOT NULL,
          attempts INTEGER NOT NULL DEFAULT 0,
          lastError TEXT
        )
      '''),
    );
  }

  /// Add a payload to the queue.
  Future<void> enqueue(CallEventPayload payload) async {
    final db = await _database;
    await db.insert(
      'crm_event_queue',
      {
        'eventId': payload.eventId,
        'payload': jsonEncode(payload.toJson()),
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'attempts': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    developer.log('CallEventQueue: enqueued ${payload.eventId}');
  }

  /// Returns all queued events ordered by creation time.
  Future<List<_QueuedItem>> _getPending() async {
    final db = await _database;
    final rows = await db.query(
      'crm_event_queue',
      orderBy: 'createdAt ASC',
    );
    return rows.map(_QueuedItem.fromRow).toList();
  }

  /// Attempt delivery for all queued events via [deliver].
  ///
  /// [deliver] should call the CRM API; it must throw on failure.
  Future<void> flushAll(
      Future<void> Function(CallEventPayload payload) deliver) async {
    final items = await _getPending();
    for (final item in items) {
      // Exponential back-off: skip if last attempt was too recent
      if (item.attempts > 0) {
        final backoffSeconds = _backoff(item.attempts);
        final nextRetry = item.createdAt
            .add(Duration(seconds: backoffSeconds));
        if (DateTime.now().isBefore(nextRetry)) continue;
      }

      try {
        await deliver(item.payload);
        await _delete(item.eventId);
        developer.log('CallEventQueue: delivered ${item.eventId}');
      } catch (e) {
        await _incrementAttempt(item.eventId, e.toString());
        developer.log(
            'CallEventQueue: delivery failed for ${item.eventId} (attempt ${item.attempts + 1}): $e',
            level: 900);
      }
    }
  }

  Future<void> _delete(String eventId) async {
    final db = await _database;
    await db.delete('crm_event_queue',
        where: 'eventId = ?', whereArgs: [eventId]);
  }

  Future<void> _incrementAttempt(String eventId, String error) async {
    final db = await _database;
    await db.rawUpdate(
      'UPDATE crm_event_queue SET attempts = attempts + 1, lastError = ? WHERE eventId = ?',
      [error, eventId],
    );
  }

  /// Back-off in seconds: 30, 60, 120, 240, 480… capped at 1 hour.
  int _backoff(int attempts) =>
      30 * (1 << attempts).clamp(1, 120);
}

class _QueuedItem {
  _QueuedItem({
    required this.eventId,
    required this.payload,
    required this.createdAt,
    required this.attempts,
  });

  factory _QueuedItem.fromRow(Map<String, dynamic> row) => _QueuedItem(
        eventId: row['eventId'] as String,
        payload: CallEventPayload.fromJson(
            jsonDecode(row['payload'] as String) as Map<String, dynamic>),
        createdAt: DateTime.fromMillisecondsSinceEpoch(row['createdAt'] as int),
        attempts: row['attempts'] as int,
      );

  final String eventId;
  final CallEventPayload payload;
  final DateTime createdAt;
  final int attempts;
}
