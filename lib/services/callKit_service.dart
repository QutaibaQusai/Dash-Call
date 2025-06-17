import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:uuid/uuid.dart';

class CallKitService {
  static String? _currentCallUuid;
  
  // Callback functions that will be set by SipService
  static Function(String)? onCallAccepted;
  static Function(String)? onCallRejected;
  static Function(String)? onCallEnded;

  /// Initialize CallKit service
  static Future<void> initialize() async {
    print('📱 [CallKit] Initializing CallKit service...');
    
    try {
      // Listen to CallKit events - FIXED: Use correct class name
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

  /// Show native incoming call screen
  static Future<void> showIncomingCall({
    required String callerName,
    required String callerNumber,
    String? avatarUrl,
  }) async {
    print('📱 [CallKit] Showing incoming call from $callerName ($callerNumber)');
    
    try {
      // Generate unique call ID
      _currentCallUuid = const Uuid().v4();
      
      // Configure CallKit parameters
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
        },
        headers: <String, dynamic>{
          'source': 'sip',
          'platform': 'flutter',
        },
        android: const AndroidParams(
          isCustomNotification: true,
          isShowLogo: false,
          ringtonePath: 'system_ringtone_default',
          backgroundColor: '#0955fa',
          actionColor: '#4CAF50',
          textColor: '#ffffff',
          incomingCallNotificationChannelName: 'Incoming Call',
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

  /// End the current call
  static Future<void> endCall() async {
    print('📱 [CallKit] Ending current call...');
    
    if (_currentCallUuid != null) {
      try {
        await FlutterCallkitIncoming.endCall(_currentCallUuid!);
        _currentCallUuid = null;
        print('✅ [CallKit] Call ended successfully');
      } catch (e) {
        print('❌ [CallKit] Failed to end call: $e');
      }
    }
  }

  /// Start an outgoing call
  static Future<void> startCall({
    required String callerName,
    required String callerNumber,
  }) async {
    print('📱 [CallKit] Starting outgoing call to $callerName ($callerNumber)');
    
    try {
      _currentCallUuid = const Uuid().v4();
      
      final callKitParams = CallKitParams(
        id: _currentCallUuid!,
        nameCaller: callerName,
        handle: callerNumber,
        type: 1, // Outgoing call
        extra: <String, dynamic>{
          'callerId': callerNumber,
          'direction': 'outgoing',
        },
        ios: const IOSParams(
          handleType: 'generic',
        ),
      );

      await FlutterCallkitIncoming.startCall(callKitParams);
      print('✅ [CallKit] Outgoing call started');
      
    } catch (e) {
      print('❌ [CallKit] Failed to start outgoing call: $e');
      throw e;
    }
  }

  /// Set call as connected
  static Future<void> setCallConnected() async {
    if (_currentCallUuid != null) {
      try {
        await FlutterCallkitIncoming.setCallConnected(_currentCallUuid!);
        print('✅ [CallKit] Call marked as connected');
      } catch (e) {
        print('❌ [CallKit] Failed to set call connected: $e');
      }
    }
  }

  /// Handle CallKit events - FIXED: Use correct class name
  static void _handleCallKitEvent(CallEvent event) {
    print('📱 [CallKit] Handling event: ${event.event}');
    
    switch (event.event) {
      case Event.actionCallIncoming:
        print('📱 [CallKit] Incoming call event');
        break;
        
      case Event.actionCallStart:
        print('📱 [CallKit] Call start event');
        break;
        
      case Event.actionCallAccept:
        print('📱 [CallKit] 🟢 Call ACCEPTED by user');
        if (onCallAccepted != null && event.body?['id'] != null) {
          onCallAccepted!(event.body!['id']);
        }
        break;
        
      case Event.actionCallDecline:
        print('📱 [CallKit] 🔴 Call DECLINED by user');
        if (onCallRejected != null && event.body?['id'] != null) {
          onCallRejected!(event.body!['id']);
        }
        _currentCallUuid = null;
        break;
        
      case Event.actionCallEnded:
        print('📱 [CallKit] Call ended event');
        if (onCallEnded != null && event.body?['id'] != null) {
          onCallEnded!(event.body!['id']);
        }
        _currentCallUuid = null;
        break;
        
      case Event.actionCallTimeout:
        print('📱 [CallKit] Call timeout');
        _currentCallUuid = null;
        break;
        
      case Event.actionCallCallback:
        print('📱 [CallKit] Call callback');
        break;
        
      case Event.actionCallToggleHold:
        print('📱 [CallKit] Toggle hold');
        break;
        
      case Event.actionCallToggleMute:
        print('📱 [CallKit] Toggle mute');
        break;
        
      case Event.actionCallToggleDmtf:
        print('📱 [CallKit] Toggle DTMF');
        break;
        
      case Event.actionCallToggleGroup:
        print('📱 [CallKit] Toggle group');
        break;
        
      case Event.actionCallToggleAudioSession:
        print('📱 [CallKit] Toggle audio session');
        break;
        
      default:
        print('📱 [CallKit] Other event: ${event.event}');
        break;
    }
  }

  /// Get current call UUID
  static String? get currentCallUuid => _currentCallUuid;
  
  /// Check if there's an active call
  static bool get hasActiveCall => _currentCallUuid != null;
}