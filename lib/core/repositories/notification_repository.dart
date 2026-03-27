import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/app_notification.dart';

class NotificationRepository {
  NotificationRepository._();

  static final NotificationRepository instance = NotificationRepository._();

  Database? _db;

  Future<Database> get _database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'notifications.db'),
      version: 1,
      onCreate: (db, version) => db.execute('''
        CREATE TABLE notifications (
          id TEXT PRIMARY KEY,
          type TEXT NOT NULL,
          title TEXT NOT NULL,
          body TEXT NOT NULL,
          scheduledAt INTEGER NOT NULL,
          deliveredAt INTEGER,
          status TEXT NOT NULL,
          studentId TEXT,
          phoneNumber TEXT,
          contactName TEXT,
          metadata TEXT NOT NULL DEFAULT '{}'
        )
      '''),
    );
  }

  Map<String, dynamic> _toRow(AppNotification n) => {
        'id': n.id,
        'type': n.type.name,
        'title': n.title,
        'body': n.body,
        'scheduledAt': n.scheduledAt.millisecondsSinceEpoch,
        'deliveredAt': n.deliveredAt?.millisecondsSinceEpoch,
        'status': n.status.name,
        'studentId': n.studentId,
        'phoneNumber': n.phoneNumber,
        'contactName': n.contactName,
        'metadata': '{}',
      };

  AppNotification _fromRow(Map<String, dynamic> row) => AppNotification(
        id: row['id'] as String,
        type: NotificationType.values.byName(row['type'] as String),
        title: row['title'] as String,
        body: row['body'] as String,
        scheduledAt:
            DateTime.fromMillisecondsSinceEpoch(row['scheduledAt'] as int),
        deliveredAt: row['deliveredAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(row['deliveredAt'] as int)
            : null,
        status: NotificationStatus.values.byName(row['status'] as String),
        studentId: row['studentId'] as String?,
        phoneNumber: row['phoneNumber'] as String?,
        contactName: row['contactName'] as String?,
      );

  Future<void> upsertNotification(AppNotification n) async {
    final db = await _database;
    await db.insert(
      'notifications',
      _toRow(n),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertAll(List<AppNotification> notifications) async {
    final db = await _database;
    final batch = db.batch();
    for (final n in notifications) {
      batch.insert('notifications', _toRow(n),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<AppNotification>> getPending() async {
    final db = await _database;
    final rows = await db.query(
      'notifications',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'scheduledAt ASC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<List<AppNotification>> getAll() async {
    final db = await _database;
    final rows = await db.query('notifications', orderBy: 'scheduledAt DESC');
    return rows.map(_fromRow).toList();
  }

  Future<int> getUnreadCount() async {
    final db = await _database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as cnt FROM notifications WHERE status IN ('pending','delivered')",
    );
    return result.first['cnt'] as int? ?? 0;
  }

  Future<void> updateStatus(String id, NotificationStatus status,
      {DateTime? deliveredAt}) async {
    final db = await _database;
    await db.update(
      'notifications',
      {
        'status': status.name,
        if (deliveredAt != null)
          'deliveredAt': deliveredAt.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteOlderThan(Duration age) async {
    final db = await _database;
    final cutoff =
        DateTime.now().subtract(age).millisecondsSinceEpoch;
    await db.delete(
      'notifications',
      where: 'scheduledAt < ?',
      whereArgs: [cutoff],
    );
  }
}
