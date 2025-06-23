// lib/services/callkit_service.dart - FIXED: Improved CallKit event handling

import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:uuid/uuid.dart';

class CallKitService {
  static String? _currentCallUuid;
  static bool _isOutgoingCall = false;
  
  // Callback functions that will be set by SipService
  static Function(String)? onCallAccepted;
  static Function(String)? onCallRejected;
  static Function(String)? onCallEnded;

  /// Initialize CallKit service
  static Future<void> initialize() async {
    print('📱 [CallKit] Initializing CallKit service...');
    
    try {
      // Listen to CallKit events
      FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
        print('📱 [CallKit] Event received: ${event?.event}');
        
        if (event != null) {
          _handleCallKitEvent(event);
        }
      });
      
      print('✅ [CallKit] CallKit service initialized successfully');
    } catch (e) {
      print('❌ [CallKit] Failed to initialize CallKit: $e');
    }
  }

  /// Show native incoming call screen - FIXED: Enhanced for better reliability
  static Future<void> showIncomingCall({
    required String callerName,
    required String callerNumber,
    String? avatarUrl,
  }) async {
    print('📱 [CallKit] Showing incoming call from $callerName ($callerNumber)');
    
    try {
      // Generate unique call ID
      _currentCallUuid = const Uuid().v4();
      _isOutgoingCall = false; // Mark as incoming call
      
      // FIXED: Enhanced CallKit parameters for better compatibility
      final callKitParams = CallKitParams(
        id: _currentCallUuid!,
        nameCaller: callerName,
        appName: 'DashCall',
        avatar: avatarUrl ?? 'https://i.pravatar.cc/100',
        handle: callerNumber,
        type: 0, // Audio call
        textAccept: 'Accept',
        textDecline: 'Decline',
        duration: 30000, // 30 seconds timeout
        extra: <String, dynamic>{
          'callerId': callerNumber,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'direction': 'incoming',
          'callType': 'sip',
        },
        headers: <String, dynamic>{
          'source': 'sip',
          'platform': 'flutter',
          'version': '1.0',
        },
        android: const AndroidParams(
          isCustomNotification: true,
          isShowLogo: false,
          ringtonePath: 'system_ringtone_default',
          backgroundColor: '#0955fa',
          actionColor: '#4CAF50',
          textColor: '#ffffff',
          incomingCallNotificationChannelName: 'Incoming Call',
          // FIXED: Additional Android parameters
          isShowCallID: true,
          isShowFullLockedScreen: true,
        ),
        
        ios: const IOSParams(
          iconName: 'CallKitLogo',
          handleType: 'generic',
          supportsVideo: false,
          maximumCallGroups: 2,
          maximumCallsPerCallGroup: 1,
          audioSessionMode: 'default',
          audioSessionActive: true,
          audioSessionPreferredSampleRate: 44100.0,
          audioSessionPreferredIOBufferDuration: 0.005,
          supportsDTMF: true,
          supportsHolding: true,
          supportsGrouping: false,
          supportsUngrouping: false,
          ringtonePath: 'system_ringtone_default',
        ),
      );

      // Show the native call screen
      await FlutterCallkitIncoming.showCallkitIncoming(callKitParams);
      print('✅ [CallKit] Native incoming call screen displayed');
      
    } catch (e) {
      print('❌ [CallKit] Failed to show incoming call: $e');
      throw e;
    }
  }

  /// End the current call - FIXED: Better error handling
  static Future<void> endCall() async {
    print('📱 [CallKit] Ending current call...');
    
    if (_currentCallUuid != null) {
      try {
        await FlutterCallkitIncoming.endCall(_currentCallUuid!);
        print('✅ [CallKit] Call ended successfully: $_currentCallUuid');
        
        // Clear state
        _currentCallUuid = null;
        _isOutgoingCall = false;
      } catch (e) {
        print('❌ [CallKit] Failed to end call: $e');
        // Still clear state even if ending failed
        _currentCallUuid = null;
        _isOutgoingCall = false;
      }
    } else {
      print('⚠️ [CallKit] No current call UUID to end');
    }
  }

  /// Start an outgoing call - FIXED: Removed for VoIP apps
  static Future<void> startCall({
    required String callerName,
    required String callerNumber,
  }) async {
    print('📱 [CallKit] Starting outgoing call to $callerName ($callerNumber)');
    
    try {
      _currentCallUuid = const Uuid().v4();
      _isOutgoingCall = true; // Mark as outgoing call
      
      // FIXED: For VoIP apps, we typically don't use CallKit for outgoing calls
      // The Flutter UI should handle outgoing calls
      print('ℹ️ [CallKit] Outgoing calls handled by Flutter UI, not CallKit');
      
    } catch (e) {
      print('❌ [CallKit] Failed to start outgoing call: $e');
      throw e;
    }
  }

  /// Set call as connected - FIXED: Better error handling
  static Future<void> setCallConnected() async {
    if (_currentCallUuid != null) {
      try {
        await FlutterCallkitIncoming.setCallConnected(_currentCallUuid!);
        print('✅ [CallKit] Call marked as connected: $_currentCallUuid');
      } catch (e) {
        print('❌ [CallKit] Failed to set call connected: $e');
        // Don't throw - this is not critical
      }
    } else {
      print('⚠️ [CallKit] No current call UUID to mark as connected');
    }
  }

  /// Handle CallKit events - FIXED: Improved event handling
  static void _handleCallKitEvent(CallEvent event) {
    final eventType = event.event;
    final callId = event.body?['id'] as String?;
    
    print('📱 [CallKit] Handling event: $eventType for call: $callId');
    
    switch (eventType) {
      case Event.actionCallIncoming:
        print('📱 [CallKit] ➡️ Incoming call event');
        // Just log - the actual incoming call display is triggered by SIP
        break;
        
      case Event.actionCallStart:
        print('📱 [CallKit] ➡️ Call start event');
        // Handle outgoing call start if needed
        break;
        
      case Event.actionCallAccept:
        print('📱 [CallKit] 🟢 Call ACCEPTED by user');
        
        // FIXED: Only handle accept for incoming calls with proper validation
        if (!_isOutgoingCall && callId != null && callId == _currentCallUuid) {
          print('📞 [CallKit] Processing accept for incoming call: $callId');
          if (onCallAccepted != null) {
            onCallAccepted!(callId);
          }
        } else {
          print('⚠️ [CallKit] Ignoring accept event - outgoing call or UUID mismatch');
          print('   - Is outgoing: $_isOutgoingCall');
          print('   - Event call ID: $callId');
          print('   - Current UUID: $_currentCallUuid');
        }
        break;
        
      case Event.actionCallDecline:
        print('📱 [CallKit] 🔴 Call DECLINED by user');
        if (callId != null && onCallRejected != null) {
          onCallRejected!(callId);
        }
        _clearCallState();
        break;
        
      case Event.actionCallEnded:
        print('📱 [CallKit] ➡️ Call ended event');
        if (callId != null && onCallEnded != null) {
          onCallEnded!(callId);
        }
        _clearCallState();
        break;
        
      case Event.actionCallTimeout:
        print('📱 [CallKit] ⏰ Call timeout');
        if (callId != null && onCallRejected != null) {
          // Treat timeout as rejection
          onCallRejected!(callId);
        }
        _clearCallState();
        break;
        
      case Event.actionCallCallback:
        print('📱 [CallKit] 📞 Call callback (Android missed call)');
        // Handle callback from missed call notification if needed
        break;
        
      case Event.actionCallToggleHold:
        print('📱 [CallKit] ⏸️ Toggle hold (iOS)');
        // Handle hold toggle if needed
        break;
        
      case Event.actionCallToggleMute:
        print('📱 [CallKit] 🔇 Toggle mute (iOS)');
        // Handle mute toggle if needed
        break;
        
      case Event.actionCallToggleDmtf:
        print('📱 [CallKit] 🔢 Toggle DTMF (iOS)');
        // Handle DTMF toggle if needed
        break;
        
      case Event.actionCallToggleGroup:
        print('📱 [CallKit] 👥 Toggle group (iOS)');
        // Handle group toggle if needed
        break;
        
      case Event.actionCallToggleAudioSession:
        print('📱 [CallKit] 🎧 Toggle audio session (iOS)');
        // Handle audio session toggle if needed
        break;
        
      default:
        print('📱 [CallKit] ❓ Unknown event: $eventType');
        break;
    }
  }

  /// FIXED: Clear call state helper
  static void _clearCallState() {
    print('🧹 [CallKit] Clearing call state');
    _currentCallUuid = null;
    _isOutgoingCall = false;
  }

  /// Get current call UUID
  static String? get currentCallUuid => _currentCallUuid;
  
  /// Check if there's an active call
  static bool get hasActiveCall => _currentCallUuid != null;
  
  /// Check if current call is outgoing
  static bool get isOutgoingCall => _isOutgoingCall;

  /// FIXED: Force clear state (useful for cleanup)
  static void forceClearState() {
    print('🧹 [CallKit] Force clearing all state');
    _currentCallUuid = null;
    _isOutgoingCall = false;
  }

  /// FIXED: Hide any active CallKit screens
  static Future<void> hideCallkitIncoming() async {
    if (_currentCallUuid != null) {
      try {
        final params = CallKitParams(id: _currentCallUuid!);
        await FlutterCallkitIncoming.hideCallkitIncoming(params);
        print('✅ [CallKit] Hidden CallKit screen for: $_currentCallUuid');
      } catch (e) {
        print('❌ [CallKit] Failed to hide CallKit screen: $e');
      }
    }
  }
}