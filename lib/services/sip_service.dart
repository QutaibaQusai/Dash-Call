import 'package:flutter/material.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'callkit_service.dart'; // Import our new CallKit service

enum SipConnectionStatus { 
  disconnected, 
  connecting, 
  connected, 
  error 
}

enum CallStatus { 
  idle, 
  calling, 
  incoming, 
  active, 
  held, 
  ended 
}

class SipService extends ChangeNotifier implements SipUaHelperListener {
  SIPUAHelper? _helper;
  SipConnectionStatus _status = SipConnectionStatus.disconnected;
  CallStatus _callStatus = CallStatus.idle;
  String? _errorMessage;
  String? _statusMessage;
  
  // Connection state tracking
  bool _isConnecting = false;
  bool _isRegistered = false;
  
  // SIP Configuration
  String _sipServer = '';
  String _username = '';
  String _password = '';
  String _domain = '';
  int _port = 8088;  // Default to WebSocket port
  
  // Current call
  Call? _currentCall;
  String? _callNumber;
  DateTime? _callStartTime;
  
  // CallKit integration - NEW
  bool _useNativeCallUI = true; // Flag to enable/disable native UI

  // Getters
  SipConnectionStatus get status => _status;
  CallStatus get callStatus => _callStatus;
  String? get errorMessage => _errorMessage;
  String? get statusMessage => _statusMessage;
  String get sipServer => _sipServer;
  String get username => _username;
  String get password => _password;
  String get domain => _domain;
  int get port => _port;
  Call? get currentCall => _currentCall;
  String? get callNumber => _callNumber;
  DateTime? get callStartTime => _callStartTime;
  bool get isConnecting => _isConnecting;
  bool get isRegistered => _isRegistered;
  bool get useNativeCallUI => _useNativeCallUI; // NEW getter

  Future<void> initialize() async {
    try {
      print('🚀 [SipService] Starting initialization...');
      _setStatusMessage('Initializing SIP client...');
      
      // Initialize CallKit service - NEW
      await CallKitService.initialize();
      
      // Set up CallKit callbacks - NEW
      CallKitService.onCallAccepted = _onCallKitAccepted;
      CallKitService.onCallRejected = _onCallKitRejected;
      CallKitService.onCallEnded = _onCallKitEnded;
      
      print('🔧 [SipService] Creating SIPUAHelper instance...');
      _helper = SIPUAHelper();
      
      if (_helper == null) {
        print('❌❌❌ [SipService] CRITICAL: Failed to create SIPUAHelper - it\'s null!');
        throw Exception('Failed to create SIPUAHelper instance');
      }
      
      print('✅ [SipService] SIPUAHelper created successfully');
      print('🎧 [SipService] Adding SipUaHelperListener...');
      
      _helper!.addSipUaHelperListener(this);
      print('✅ [SipService] SIPUAHelper listener added');
      
      // Load saved settings
      print('📂 [SipService] Loading saved settings...');
      await _loadSettings();
      print('✅ [SipService] Settings loaded from storage');
      
      _setStatusMessage('SIP client initialized. Configure settings to connect.');
      print('🎉 [SipService] Initialization completed successfully');
    } catch (e, stackTrace) {
      print('❌ [SipService] Initialization failed: $e');
      print('📍 [SipService] Full stack trace: $stackTrace');
      _setError('Failed to initialize SIP client: $e');
    }
  }

  // NEW: CallKit callback handlers
  void _onCallKitAccepted(String callUuid) {
    print('🟢 [SipService] CallKit: User ACCEPTED call $callUuid');
    answerCall();
  }

  void _onCallKitRejected(String callUuid) {
    print('🔴 [SipService] CallKit: User REJECTED call $callUuid');
    rejectCall();
  }

  void _onCallKitEnded(String callUuid) {
    print('📞 [SipService] CallKit: Call ENDED $callUuid');
    hangupCall();
  }

  Future<void> _loadSettings() async {
    print('📂 [SipService] Loading settings from SharedPreferences...');
    final prefs = await SharedPreferences.getInstance();
    
    _sipServer = prefs.getString('sip_server') ?? '';
    _username = prefs.getString('sip_username') ?? '';
    _password = prefs.getString('sip_password') ?? '';
    _domain = prefs.getString('sip_domain') ?? '';
    _port = prefs.getInt('sip_port') ?? 8088;
    _useNativeCallUI = prefs.getBool('use_native_call_ui') ?? true; // NEW
    
    print('📋 [SipService] Loaded settings:');
    print('   Server: $_sipServer');
    print('   Username: $_username');
    print('   Password: ${_password.isNotEmpty ? '[${_password.length} chars]' : '[empty]'}');
    print('   Domain: $_domain');
    print('   Port: $_port');
    print('   Use Native UI: $_useNativeCallUI'); // NEW
    
    notifyListeners();
  }

  Future<void> saveSettings(String server, String username, String password, String domain, int port) async {
    print('💾 [SipService] Saving new settings...');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sip_server', server);
    await prefs.setString('sip_username', username);
    await prefs.setString('sip_password', password);
    await prefs.setString('sip_domain', domain);
    await prefs.setInt('sip_port', port);
    
    _sipServer = server;
    _username = username;
    _password = password;
    _domain = domain;
    _port = port;
    
    print('✅ [SipService] Settings saved to SharedPreferences');
    notifyListeners();
  }

  // NEW: Toggle between native and Flutter UI
  Future<void> toggleNativeCallUI(bool useNative) async {
    _useNativeCallUI = useNative;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_native_call_ui', useNative);
    notifyListeners();
    print('📱 [SipService] Native call UI: ${useNative ? 'ENABLED' : 'DISABLED'}');
  }

  Future<bool> register() async {
    print('🔐 [SipService] Starting registration process...');
    
    if (_isConnecting) {
      print('⚠️ [SipService] Already connecting, ignoring duplicate request');
      return false;
    }
    
    if (_isRegistered && _status == SipConnectionStatus.connected) {
      print('✅ [SipService] Already registered and connected');
      return true;
    }

    if (_sipServer.isEmpty || _username.isEmpty || _password.isEmpty) {
      print('❌ [SipService] Missing required settings');
      _setError('Please configure SIP settings first');
      return false;
    }

    _isConnecting = true;
    
    try {
      _setStatus(SipConnectionStatus.connecting);
      _setStatusMessage('Connecting to $_sipServer...');
      print('🌐 [SipService] Attempting to connect to $_sipServer:$_port');
      
      await _cleanupExistingConnection();
      
      print('🔄 [SipService] Creating fresh SIPUAHelper instance...');
      _helper = SIPUAHelper();
      _helper!.addSipUaHelperListener(this);
      
      print('⚙️ [SipService] Creating UaSettings...');
      UaSettings settings = UaSettings();
      
      final wsUrl = 'wss://$_sipServer:$_port/ws';
      final sipUri = 'sip:$_username@${_domain.isEmpty ? _sipServer : _domain}';
      final displayName = _username.isNotEmpty ? _username : 'DashCall User';
      
      settings.webSocketUrl = wsUrl;
      settings.uri = sipUri;
      settings.authorizationUser = _username;
      settings.password = _password;
      settings.displayName = displayName;
      settings.userAgent = 'DashCall 1.0';
      settings.register = true;
      settings.transportType = TransportType.WS;
      
      settings.iceServers = [
        {'urls': 'stun:stun.l.google.com:19302'},
      ];
      
      settings.dtmfMode = DtmfMode.RFC2833;
      
      print('🚀 [SipService] Executing _helper.start(settings)...');
      await _helper!.start(settings);
      print('✅ [SipService] _helper.start() completed successfully');
      
      return true;
    } catch (e, stackTrace) {
      print('❌ [SipService] Registration failed with exception: $e');
      _setError('Registration failed: $e');
      _setStatus(SipConnectionStatus.error);
      _isConnecting = false;
      return false;
    }
  }

  Future<void> _cleanupExistingConnection() async {
    print('🧹 [SipService] Cleaning up existing connection...');
    
    if (_helper != null) {
      try {
        _isRegistered = false;
        _helper!.stop();
        await Future.delayed(const Duration(milliseconds: 100));
        _helper!.removeSipUaHelperListener(this);
        _helper = null;
        print('✅ [SipService] Old connection cleaned up successfully');
      } catch (e) {
        print('⚠️ [SipService] Error during cleanup (continuing anyway): $e');
      }
    }
  }

  Future<void> unregister() async {
    print('📤 [SipService] Starting unregistration...');
    _isRegistered = false;
    _isConnecting = false;
    
    if (_helper != null) {
      try {
        _helper!.stop();
        await Future.delayed(const Duration(milliseconds: 100));
        _setStatus(SipConnectionStatus.disconnected);
        _setStatusMessage('Disconnected');
        print('✅ [SipService] Successfully unregistered');
      } catch (e) {
        print('❌ [SipService] Unregister error: $e');
        _setError('Failed to unregister: $e');
      }
    }
  }

  Future<bool> makeCall(String phoneNumber) async {
    print('📞 [SipService] Attempting to make call to: $phoneNumber');
    
    if (_helper == null || _status != SipConnectionStatus.connected) {
      print('❌ [SipService] Cannot make call');
      _setError('Not connected to SIP server');
      return false;
    }

    if (phoneNumber.isEmpty) {
      print('❌ [SipService] Phone number is empty');
      _setError('Please enter a phone number');
      return false;
    }

    try {
      print('🚀 [SipService] Starting call to $phoneNumber');
      _setStatusMessage('Calling $phoneNumber...');
      _callNumber = phoneNumber;
      _callStartTime = DateTime.now();
      
      // Show native outgoing call UI if enabled - NEW
      if (_useNativeCallUI) {
        await CallKitService.startCall(
          callerName: phoneNumber,
          callerNumber: phoneNumber,
        );
      }
      
      _helper!.call(phoneNumber);
      print('✅ [SipService] Call initiated successfully');
      _setCallStatus(CallStatus.calling);
      return true;
    } catch (e) {
      print('❌ [SipService] Call failed with exception: $e');
      _setError('Failed to make call: $e');
      return false;
    }
  }

  Future<void> answerCall() async {
    print('✅ [SipService] Attempting to answer call...');
    if (_currentCall != null) {
      try {
        print('📞 [SipService] Calling answer() on current call');
        _currentCall!.answer(_helper!.buildCallOptions());
        _callStartTime = DateTime.now();
        _setCallStatus(CallStatus.active);
        _setStatusMessage('Call active');
        
        // Mark call as connected in CallKit - NEW
        if (_useNativeCallUI) {
          await CallKitService.setCallConnected();
        }
        
        print('✅ [SipService] Call answered successfully');
      } catch (e) {
        print('❌ [SipService] Failed to answer call: $e');
        _setError('Failed to answer call: $e');
      }
    } else {
      print('❌ [SipService] No current call to answer');
      _setError('No incoming call to answer');
    }
  }

  Future<void> rejectCall() async {
    print('❌ [SipService] Attempting to reject call...');
    if (_currentCall != null) {
      try {
        print('📞 [SipService] Calling hangup() to reject call');
        _currentCall!.hangup();
        
        // End call in CallKit - NEW
        if (_useNativeCallUI) {
          await CallKitService.endCall();
        }
        
        _endCall();
        print('✅ [SipService] Call rejected successfully');
      } catch (e) {
        print('❌ [SipService] Failed to reject call: $e');
        _setError('Failed to reject call: $e');
      }
    } else {
      print('❌ [SipService] No current call to reject');
      _setError('No incoming call to reject');
    }
  }

  Future<void> hangupCall() async {
    if (_currentCall != null) {
      try {
        _currentCall!.hangup();
        
        // End call in CallKit - NEW
        if (_useNativeCallUI) {
          await CallKitService.endCall();
        }
        
        _endCall();
      } catch (e) {
        _setError('Failed to hangup call: $e');
      }
    }
  }

  Future<void> holdCall() async {
    if (_currentCall != null && _callStatus == CallStatus.active) {
      try {
        _currentCall!.hold();
        _setCallStatus(CallStatus.held);
        _setStatusMessage('Call on hold');
      } catch (e) {
        _setError('Failed to hold call: $e');
      }
    }
  }

  Future<void> resumeCall() async {
    if (_currentCall != null && _callStatus == CallStatus.held) {
      try {
        _currentCall!.unhold();
        _setCallStatus(CallStatus.active);
        _setStatusMessage('Call resumed');
      } catch (e) {
        _setError('Failed to resume call: $e');
      }
    }
  }

  Future<void> sendDTMF(String dtmf) async {
    if (_currentCall != null && _callStatus == CallStatus.active) {
      try {
        _currentCall!.sendDTMF(dtmf);
      } catch (e) {
        _setError('Failed to send DTMF: $e');
      }
    }
  }

  // CRITICAL: Updated call state handling
  @override
  void callStateChanged(Call call, CallState state) {
    print('📱 [SipService] Call state changed: ${state.state}');
    print('   Call ID: ${call.id}');
    print('   Remote identity: ${call.remote_identity}');
    print('   Direction: ${call.direction}');
    
    _currentCall = call;
    
    // CRITICAL: Check if this is an incoming call - UPDATED FOR CALLKIT
    if (call.direction == 'INCOMING' && state.state == CallStateEnum.CALL_INITIATION) {
      print('📲 [SipService] 🚨 INCOMING CALL DETECTED! 🚨');
      _callNumber = call.remote_identity ?? 'Unknown';
      
      if (_useNativeCallUI) {
        // Show native CallKit UI instead of Flutter UI - NEW
        print('📱 [SipService] Showing native CallKit incoming call screen');
        _showNativeIncomingCall(call.remote_identity ?? 'Unknown');
        // Don't set to incoming status - let CallKit handle the UI
      } else {
        // Use Flutter UI - FALLBACK
        print('📱 [SipService] Using Flutter incoming call UI');
        _setCallStatus(CallStatus.incoming);
        _setStatusMessage('Incoming call from ${call.remote_identity ?? 'Unknown'}');
      }
      return;
    }
    
    switch (state.state) {
      case CallStateEnum.CALL_INITIATION:
        print('🚀 [CallState] Call initiation');
        if (call.direction == 'OUTGOING') {
          _setCallStatus(CallStatus.calling);
          _setStatusMessage('Initiating call...');
        }
        break;
      case CallStateEnum.PROGRESS:
        print('📞 [CallState] Call in progress');
        if (call.direction == 'OUTGOING') {
          _setStatusMessage('Call in progress...');
        }
        if (call.direction == 'INCOMING' && _callStatus == CallStatus.incoming) {
          _setStatusMessage('Incoming call ringing...');
        }
        break;
      case CallStateEnum.ACCEPTED:
      case CallStateEnum.CONFIRMED:
        print('✅ [CallState] Call accepted/confirmed');
        _setCallStatus(CallStatus.active);
        _setStatusMessage('Call connected');
        if (_callStartTime == null) {
          _callStartTime = DateTime.now();
        }
        
        // Mark as connected in CallKit - NEW
        if (_useNativeCallUI) {
          CallKitService.setCallConnected();
        }
        break;
      case CallStateEnum.ENDED:
      case CallStateEnum.FAILED:
        print('❌ [CallState] Call ended/failed');
        if (state.cause != null) {
          print('   Cause: ${state.cause}');
        }
        
        // End call in CallKit - NEW
        if (_useNativeCallUI) {
          CallKitService.endCall();
        }
        
        _endCall();
        break;
      case CallStateEnum.HOLD:
        print('⏸️ [CallState] Call on hold');
        _setCallStatus(CallStatus.held);
        break;
      case CallStateEnum.UNHOLD:
        print('▶️ [CallState] Call resumed from hold');
        _setCallStatus(CallStatus.active);
        break;
      case CallStateEnum.MUTED:
      case CallStateEnum.UNMUTED:
        print('🔇 [CallState] Mute state changed: ${state.state}');
        break;
      case CallStateEnum.STREAM:
        print('🎵 [CallState] Media stream event');
        break;
      case CallStateEnum.REFER:
        print('🔄 [CallState] Call transfer/refer');
        break;
      case CallStateEnum.NONE:
        print('⚪ [CallState] No call state');
        _setStatusMessage('Call state: none');
        break;
      case CallStateEnum.CONNECTING:
        print('🔗 [CallState] Call connecting');
        _setStatusMessage('Call connecting...');
        break;
    }
  }

  // NEW: Show native incoming call using CallKit
  Future<void> _showNativeIncomingCall(String callerNumber) async {
    try {
      String callerName = callerNumber;
      
      await CallKitService.showIncomingCall(
        callerName: callerName,
        callerNumber: callerNumber,
        avatarUrl: null,
      );
      
      print('✅ [SipService] Native incoming call UI displayed');
    } catch (e) {
      print('❌ [SipService] Failed to show native incoming call: $e');
      // Fallback to Flutter UI
      _setCallStatus(CallStatus.incoming);
      _setStatusMessage('Incoming call from $callerNumber');
    }
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    print('🔐 [SipService] Registration state changed: ${state.state}');
    if (state.cause != null) {
      print('   Cause: ${state.cause}');
    }
    
    switch (state.state) {
      case RegistrationStateEnum.REGISTERED:
        print('✅ [Registration] Successfully registered');
        _isRegistered = true;
        _isConnecting = false;
        _setStatus(SipConnectionStatus.connected);
        _setStatusMessage('Registered successfully');
        break;
      case RegistrationStateEnum.UNREGISTERED:
        print('📤 [Registration] Unregistered');
        _isRegistered = false;
        if (!_isConnecting) {
          _setStatus(SipConnectionStatus.disconnected);
          _setStatusMessage('Unregistered');
        }
        break;
      case RegistrationStateEnum.REGISTRATION_FAILED:
        print('❌ [Registration] Registration failed');
        if (state.cause != null) {
          print('   Error details: ${state.cause}');
        }
        _isRegistered = false;
        _isConnecting = false;
        _setStatus(SipConnectionStatus.error);
        _setError('Registration failed: ${state.cause ?? 'Unknown error'}');
        break;
      case RegistrationStateEnum.NONE:
        print('⚪ [Registration] No registration state');
        _setStatusMessage('Registration state: none');
        break;
      case null:
        print('❓ [Registration] Unknown registration state');
        _setStatusMessage('Registration state unknown');
        break;
    }
  }

  @override
  void transportStateChanged(TransportState state) {
    print('🌐 [SipService] Transport state changed: ${state.state}');
    if (state.cause != null) {
      print('   Cause: ${state.cause}');
    }
    
    switch (state.state) {
      case TransportStateEnum.CONNECTED:
        print('✅ [Transport] Connected');
        _setStatusMessage('Transport connected');
        break;
      case TransportStateEnum.CONNECTING:
        print('🔗 [Transport] Connecting');
        _setStatusMessage('Connecting...');
        break;
      case TransportStateEnum.DISCONNECTED:
        print('❌ [Transport] Disconnected');
        if (_status == SipConnectionStatus.connected) {
          _isRegistered = false;
          _setStatus(SipConnectionStatus.disconnected);
          _setStatusMessage('Connection lost');
        }
        break;
      case TransportStateEnum.NONE:
        print('⚪ [Transport] No transport state');
        break;
    }
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {
    print('📨 [SipService] New SIP message received: ${msg.toString()}');
  }

  @override
  void onNewNotify(Notify ntf) {
    print('🔔 [SipService] New SIP notify received: ${ntf.toString()}');
  }

  @override
  void onNewReinvite(ReInvite reinvite) {
    print('🔄 [SipService] New re-invite received: ${reinvite.toString()}');
  }

  void _endCall() {
    _currentCall = null;
    _callNumber = null;
    _callStartTime = null;
    _setCallStatus(CallStatus.idle);
    _setStatusMessage('Call ended');
  }

  void _setStatus(SipConnectionStatus status) {
    print('📊 [SipService] Status changed: $_status -> $status');
    _status = status;
    notifyListeners();
  }

  void _setCallStatus(CallStatus status) {
    print('📱 [SipService] Call status changed: $_callStatus -> $status');
    _callStatus = status;
    notifyListeners();
  }

  void _setError(String error) {
    print('❌ [SipService] Error: $error');
    _errorMessage = error;
    _statusMessage = error;
    notifyListeners();
  }

  void _setStatusMessage(String message) {
    print('📋 [SipService] Status: $message');
    _statusMessage = message;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    print('🗑️ [SipService] Disposing SIP service...');
    _isConnecting = false;
    _isRegistered = false;
    
    if (_helper != null) {
      try {
        _helper!.stop();
        _helper!.removeSipUaHelperListener(this);
        print('✅ [SipService] SIP helper stopped successfully');
      } catch (e) {
        print('❌ [SipService] Error stopping SIP helper: $e');
      }
    }
    super.dispose();
  }
}