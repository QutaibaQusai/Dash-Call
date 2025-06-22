// lib/services/call_history_database.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

enum CallType { incoming, outgoing, missed }

class CallRecord {
  final String id;
  final String number;
  final String? name;
  final CallType type;
  final DateTime timestamp;
  final Duration duration;

  CallRecord({
    required this.id,
    required this.number,
    this.name,
    required this.type,
    required this.timestamp,
    required this.duration,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'name': name,
      'type': type.index,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'duration': duration.inSeconds,
    };
  }

  factory CallRecord.fromJson(Map<String, dynamic> json) {
    return CallRecord(
      id: json['id'],
      number: json['number'],
      name: json['name'],
      type: CallType.values[json['type']],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      duration: Duration(seconds: json['duration']),
    );
  }
}

class CallHistoryDatabase {
  static Database? _database;
  static const String _tableName = 'call_history';

  /// Initialize database
  static Future<void> initialize() async {
    if (_database != null) return;

    try {
      final databasePath = await getDatabasesPath();
      final path = join(databasePath, 'call_history.db');

      _database = await openDatabase(
        path,
        version: 1,
        onCreate: _createDatabase,
        onUpgrade: _upgradeDatabase,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Create database tables
  static Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id TEXT PRIMARY KEY,
        number TEXT NOT NULL,
        name TEXT,
        type INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        duration INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000)
      )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_timestamp ON $_tableName (timestamp DESC)');
    await db.execute('CREATE INDEX idx_type ON $_tableName (type)');
    await db.execute('CREATE INDEX idx_number ON $_tableName (number)');
  }

  /// Upgrade database schema
  static Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // Handle future database migrations here
  }

  /// Get database instance
  static Future<Database> get database async {
    if (_database == null) {
      await initialize();
    }
    return _database!;
  }

  /// Insert a new call record
  static Future<void> insertCall(CallRecord call) async {
    try {
      final db = await database;
      await db.insert(
        _tableName,
        call.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      // Silently handle errors in production
    }
  }

  /// Get all calls ordered by timestamp (newest first)
  static Future<List<CallRecord>> getAllCalls({int? limit}) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: 'timestamp DESC',
        limit: limit,
      );

      return maps.map((map) => CallRecord.fromJson(map)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get calls by type
  static Future<List<CallRecord>> getCallsByType(CallType type, {int? limit}) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'type = ?',
        whereArgs: [type.index],
        orderBy: 'timestamp DESC',
        limit: limit,
      );

      return maps.map((map) => CallRecord.fromJson(map)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Update call duration
  static Future<void> updateCallDuration(String number, Duration duration) async {
    try {
      final db = await database;
      
      // Find the most recent call with this number that has zero duration
      final List<Map<String, dynamic>> recentCalls = await db.query(
        _tableName,
        where: 'number = ? AND duration = 0',
        whereArgs: [number],
        orderBy: 'timestamp DESC',
        limit: 1,
      );

      if (recentCalls.isNotEmpty) {
        final callId = recentCalls.first['id'];
        await db.update(
          _tableName,
          {'duration': duration.inSeconds},
          where: 'id = ?',
          whereArgs: [callId],
        );
      }
    } catch (e) {
      // Silently handle errors in production
    }
  }

  /// Mark call as missed
  static Future<void> markAsMissed(String number) async {
    try {
      final db = await database;
      
      // Find recent incoming call within 5 minutes
      final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
      final List<Map<String, dynamic>> recentCalls = await db.query(
        _tableName,
        where: 'number = ? AND type = ? AND timestamp > ?',
        whereArgs: [number, CallType.incoming.index, fiveMinutesAgo.millisecondsSinceEpoch],
        orderBy: 'timestamp DESC',
        limit: 1,
      );

      if (recentCalls.isNotEmpty) {
        final callId = recentCalls.first['id'];
        await db.update(
          _tableName,
          {'type': CallType.missed.index},
          where: 'id = ?',
          whereArgs: [callId],
        );
      }
    } catch (e) {
      // Silently handle errors in production
    }
  }

  /// Delete a specific call
  static Future<void> deleteCall(String id) async {
    try {
      final db = await database;
      await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      // Silently handle errors in production
    }
  }

  /// Clear all call history
  static Future<void> clearAllCalls() async {
    try {
      final db = await database;
      await db.delete(_tableName);
    } catch (e) {
      // Silently handle errors in production
    }
  }

  /// Get call count by type
  static Future<int> getCallCount({CallType? type}) async {
    try {
      final db = await database;
      
      if (type != null) {
        final result = await db.rawQuery(
          'SELECT COUNT(*) as count FROM $_tableName WHERE type = ?',
          [type.index],
        );
        return result.first['count'] as int;
      } else {
        final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
        return result.first['count'] as int;
      }
    } catch (e) {
      return 0;
    }
  }

  /// Search calls by number or name
  static Future<List<CallRecord>> searchCalls(String query) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'number LIKE ? OR name LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'timestamp DESC',
      );

      return maps.map((map) => CallRecord.fromJson(map)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Close database connection
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}