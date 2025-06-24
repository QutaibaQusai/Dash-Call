// lib/services/call_manager.dart - NEW: Centralized call management
import 'package:flutter/foundation.dart';
import 'sip_service.dart';

enum CallScreenState {
  hidden,      // No active calls - show main screen
  showing,     // Active call - show CallScreen
}

class CallManager extends ChangeNotifier {
  static final CallManager _instance = CallManager._internal();
  factory CallManager() => _instance;
  CallManager._internal();

  // Current call state
  CallScreenState _screenState = CallScreenState.hidden;
  SipService? _activeCallService;

  // Getters
  CallScreenState get screenState => _screenState;
  SipService? get activeCallService => _activeCallService;
  bool get shouldShowCallScreen => _screenState == CallScreenState.showing;

  /// Called when a call becomes active (from any SIP service)
  void setActiveCall(SipService sipService) {
    print('📱 [CallManager] Setting active call for: ${sipService.username}');
    _activeCallService = sipService;
    _screenState = CallScreenState.showing;
    notifyListeners();
  }

  /// Called when a call ends (from any SIP service)
  void clearActiveCall() {
    print('📱 [CallManager] Clearing active call');
    _activeCallService = null;
    _screenState = CallScreenState.hidden;
    notifyListeners();
  }

  /// Called immediately when CallKit call is accepted
  void onCallKitAccepted(SipService sipService) {
    print('📱 [CallManager] CallKit accepted - immediately showing CallScreen');
    setActiveCall(sipService);
  }
}