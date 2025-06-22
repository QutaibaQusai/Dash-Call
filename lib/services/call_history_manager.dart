// lib/services/call_history_manager.dart

import '../services/call_history_database.dart';

class CallHistoryManager {
  static bool _isInitialized = false;

  /// Initialize the call history system
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await CallHistoryDatabase.initialize();
      _isInitialized = true;
    } catch (e) {
      // Log error in production logging system if needed
      rethrow;
    }
  }

  /// Add a new call record
  static Future<void> addCall({
    required String number,
    String? name,
    required CallType type,
    required DateTime timestamp,
    Duration duration = Duration.zero,
  }) async {
    try {
      final record = CallRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        number: number,
        name: name,
        type: type,
        timestamp: timestamp,
        duration: duration,
      );

      await CallHistoryDatabase.insertCall(record);
    } catch (e) {
      // Silently handle errors in production
    }
  }

  /// Get all calls
  static Future<List<CallRecord>> getAllCalls() async {
    try {
      return await CallHistoryDatabase.getAllCalls(limit: 100);
    } catch (e) {
      return [];
    }
  }

  /// Get incoming calls
  static Future<List<CallRecord>> getIncomingCalls() async {
    try {
      return await CallHistoryDatabase.getCallsByType(CallType.incoming, limit: 100);
    } catch (e) {
      return [];
    }
  }

  /// Get outgoing calls
  static Future<List<CallRecord>> getOutgoingCalls() async {
    try {
      return await CallHistoryDatabase.getCallsByType(CallType.outgoing, limit: 100);
    } catch (e) {
      return [];
    }
  }

  /// Get missed calls
  static Future<List<CallRecord>> getMissedCalls() async {
    try {
      return await CallHistoryDatabase.getCallsByType(CallType.missed, limit: 100);
    } catch (e) {
      return [];
    }
  }

  /// Delete a specific call
  static Future<void> deleteCall(String id) async {
    try {
      await CallHistoryDatabase.deleteCall(id);
    } catch (e) {
      // Silently handle errors in production
    }
  }

  /// Clear all call history
  static Future<void> clearHistory() async {
    try {
      await CallHistoryDatabase.clearAllCalls();
    } catch (e) {
      // Silently handle errors in production
    }
  }

  /// Update call duration (for when call ends)
  static Future<void> updateCallDuration(String number, Duration duration) async {
    try {
      await CallHistoryDatabase.updateCallDuration(number, duration);
    } catch (e) {
      // Silently handle errors in production
    }
  }

  /// Mark call as missed
  static Future<void> markAsMissed(String number) async {
    try {
      await CallHistoryDatabase.markAsMissed(number);
    } catch (e) {
      // Silently handle errors in production
    }
  }

  /// Search calls by number or name
  static Future<List<CallRecord>> searchCalls(String query) async {
    try {
      return await CallHistoryDatabase.searchCalls(query);
    } catch (e) {
      return [];
    }
  }

  /// Get call statistics
  static Future<Map<String, int>> getCallStatistics() async {
    try {
      final total = await CallHistoryDatabase.getCallCount();
      final incoming = await CallHistoryDatabase.getCallCount(type: CallType.incoming);
      final outgoing = await CallHistoryDatabase.getCallCount(type: CallType.outgoing);
      final missed = await CallHistoryDatabase.getCallCount(type: CallType.missed);

      return {
        'total': total,
        'incoming': incoming,
        'outgoing': outgoing,
        'missed': missed,
      };
    } catch (e) {
      return {'total': 0, 'incoming': 0, 'outgoing': 0, 'missed': 0};
    }
  }
}