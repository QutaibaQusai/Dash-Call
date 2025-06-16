import 'package:flutter/material.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> initialize() async {
    try {
      print('🚀 [SipService] Starting initialization...');
      _setStatusMessage('Initializing SIP client...');
      
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
      print('🔍 [SipService] Final _helper status: ${_helper != null ? 'NOT NULL' : 'NULL'}');
    } catch (e, stackTrace) {
      print('❌ [SipService] Initialization failed: $e');
      print('📍 [SipService] Full stack trace: $stackTrace');
      _setError('Failed to initialize SIP client: $e');
    }
  }

  Future<void> _loadSettings() async {
    print('📂 [SipService] Loading settings from SharedPreferences...');
    final prefs = await SharedPreferences.getInstance();
    
    _sipServer = prefs.getString('sip_server') ?? '';
    _username = prefs.getString('sip_username') ?? '';
    _password = prefs.getString('sip_password') ?? '';
    _domain = prefs.getString('sip_domain') ?? '';
    _port = prefs.getInt('sip_port') ?? 8088;  // Default to WebSocket port
    
    print('📋 [SipService] Loaded settings:');
    print('   Server: $_sipServer');
    print('   Username: $_username');
    print('   Password: ${_password.isNotEmpty ? '[${_password.length} chars]' : '[empty]'}');
    print('   Domain: $_domain');
    print('   Port: $_port');
    
    notifyListeners();
  }

  Future<void> saveSettings(String server, String username, String password, String domain, int port) async {
    print('💾 [SipService] Saving new settings...');
    print('   Server: $server');
    print('   Username: $username');
    print('   Password: ${password.isNotEmpty ? '[${password.length} chars]' : '[empty]'}');
    print('   Domain: $domain');
    print('   Port: $port');
    
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

  Future<bool> register() async {
    print('🔐 [SipService] Starting registration process...');
    
    // Prevent multiple simultaneous connection attempts
    if (_isConnecting) {
      print('⚠️ [SipService] Already connecting, ignoring duplicate request');
      return false;
    }
    
    if (_isRegistered && _status == SipConnectionStatus.connected) {
      print('✅ [SipService] Already registered and connected');
      return true;
    }
    
    // Check helper with detailed logging
    print('🔍 [SipService] Checking _helper status: ${_helper != null ? 'NOT NULL' : 'NULL'}');
    if (_helper == null) {
      print('❌ [SipService] SIP client not initialized - _helper is null');
      _setError('SIP client not initialized');
      return false;
    }

    if (_sipServer.isEmpty || _username.isEmpty || _password.isEmpty) {
      print('❌ [SipService] Missing required settings:');
      print('   Server empty: ${_sipServer.isEmpty}');
      print('   Username empty: ${_username.isEmpty}');
      print('   Password empty: ${_password.isEmpty}');
      _setError('Please configure SIP settings first');
      return false;
    }

    _isConnecting = true;
    
    try {
      _setStatus(SipConnectionStatus.connecting);
      _setStatusMessage('Connecting to $_sipServer...');
      print('🌐 [SipService] Attempting to connect to $_sipServer:$_port');
      
      // Create SIP UA settings with minimal required configuration
      print('⚙️ [SipService] Creating UaSettings...');
      UaSettings settings;
      
      try {
        settings = UaSettings();
        print('✅ [SipService] UaSettings created successfully');
      } catch (e) {
        print('❌ [SipService] Failed to create UaSettings: $e');
        throw e;
      }
      
      // WebSocket URL and SIP URI
      final wsUrl = 'wss://$_sipServer:$_port/ws';
      final sipUri = 'sip:$_username@${_domain.isEmpty ? _sipServer : _domain}';
      final displayName = _username.isNotEmpty ? _username : 'DashCall User';
      
      print('🔧 [SipService] Configuring settings...');
      
      // Set core required fields one by one with error checking
      try {
        print('   Setting webSocketUrl...');
        settings.webSocketUrl = wsUrl;
        
        print('   Setting uri...');
        settings.uri = sipUri;
        
        print('   Setting authorizationUser...');
        settings.authorizationUser = _username;
        
        print('   Setting password...');
        settings.password = _password;
        
        print('   Setting displayName...');
        settings.displayName = displayName;
        
        print('   Setting userAgent...');
        settings.userAgent = 'DashCall 1.0';
        
        print('   Setting register...');
        settings.register = true;
        
        // CRITICAL: Set the transportType - this was missing!
        print('   Setting transportType to WS...');
        settings.transportType = TransportType.WS;
        
        // WebRTC-specific settings for Asterisk compatibility
        print('   Setting WebRTC compatibility options...');
        
        // Use only basic audio codecs that Asterisk supports
        settings.iceServers = [
          {'urls': 'stun:stun.l.google.com:19302'},
        ];
        
        // Optional settings
        print('   Setting optional settings...');
        settings.dtmfMode = DtmfMode.RFC2833;
        
        print('✅ [SipService] All settings configured successfully');
        
      } catch (e) {
        print('❌ [SipService] Error setting UaSettings properties: $e');
        throw e;
      }
      
      print('⚙️ [SipService] Final registration settings:');
      print('   WebSocket URL: $wsUrl');
      print('   SIP URI: $sipUri');
      print('   Auth User: $_username');
      print('   Password: ${_password.isNotEmpty ? '[SET]' : '[EMPTY]'}');
      print('   Display Name: $displayName');
      print('   User Agent: DashCall 1.0');
      print('   Register: true');
      print('   Transport Type: WS');
      print('   DTMF Mode: RFC2833');
      
      print('📡 [SipService] About to call _helper!.start()...');
      print('🔍 [SipService] Double-checking _helper: ${_helper != null ? 'STILL NOT NULL' : 'NOW NULL!!!'}');
      
      if (_helper == null) {
        print('❌❌❌ [SipService] CRITICAL: _helper became null before start()!');
        _setError('SIP helper became null');
        _isConnecting = false;
        return false;
      }
      
      // Try to call start with detailed error handling
      try {
        print('🚀 [SipService] Executing _helper.start(settings)...');
        await _helper!.start(settings);
        print('✅ [SipService] _helper.start() completed successfully');
        
        // Don't set _isConnecting = false here, wait for actual registration callback
        return true;
      } catch (startError, startStackTrace) {
        print('❌ [SipService] _helper.start() failed: $startError');
        print('📍 [SipService] Start error stack trace: $startStackTrace');
        
        // Try to provide more specific error information
        if (startError.toString().contains('Null check operator')) {
          print('🔍 [SipService] This is a null check error inside sip_ua package');
          print('🔍 [SipService] Likely missing required UaSettings property');
        }
        
        throw startError;
      }
    } catch (e, stackTrace) {
      print('❌ [SipService] Registration failed with exception: $e');
      print('📍 [SipService] Full stack trace: $stackTrace');
      _setError('Registration failed: $e');
      _setStatus(SipConnectionStatus.error);
      _isConnecting = false;
      return false;
    }
  }

  Future<void> unregister() async {
    print('📤 [SipService] Starting unregistration...');
    _isRegistered = false;
    _isConnecting = false;
    
    if (_helper != null) {
      try {
        _helper!.stop();
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
      print('❌ [SipService] Cannot make call:');
      print('   Helper null: ${_helper == null}');
      print('   Status: $_status');
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
      
      // Make call - correct API usage for sip_ua
      print('📡 [SipService] Calling _helper.call()...');
      _helper!.call(phoneNumber);
      print('✅ [SipService] Call initiated successfully');
      _setCallStatus(CallStatus.calling);
      return true;
    } catch (e) {
      print('❌ [SipService] Call failed with exception: $e');
      print('📍 [SipService] Stack trace: ${StackTrace.current}');
      _setError('Failed to make call: $e');
      return false;
    }
  }

  Future<void> answerCall() async {
    if (_currentCall != null) {
      try {
        _currentCall!.answer(_helper!.buildCallOptions());
        _callStartTime = DateTime.now();
        _setCallStatus(CallStatus.active);
        _setStatusMessage('Call active');
      } catch (e) {
        _setError('Failed to answer call: $e');
      }
    }
  }

  Future<void> rejectCall() async {
    if (_currentCall != null) {
      try {
        _currentCall!.hangup();
        _endCall();
      } catch (e) {
        _setError('Failed to reject call: $e');
      }
    }
  }

  Future<void> hangupCall() async {
    if (_currentCall != null) {
      try {
        _currentCall!.hangup();
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

  // SipUaHelperListener implementations
  @override
  void callStateChanged(Call call, CallState state) {
    print('📱 [SipService] Call state changed: ${state.state}');
    print('   Call ID: ${call.id}');
    print('   Remote identity: ${call.remote_identity}');
    
    _currentCall = call;
    
    switch (state.state) {
      case CallStateEnum.CALL_INITIATION:
        print('🚀 [CallState] Call initiation');
        _setCallStatus(CallStatus.calling);
        _setStatusMessage('Initiating call...');
        break;
      case CallStateEnum.PROGRESS:
        print('📞 [CallState] Call in progress');
        _setStatusMessage('Call in progress...');
        break;
      case CallStateEnum.ACCEPTED:
      case CallStateEnum.CONFIRMED:
        print('✅ [CallState] Call accepted/confirmed');
        _setCallStatus(CallStatus.active);
        _setStatusMessage('Call connected');
        if (_callStartTime == null) {
          _callStartTime = DateTime.now();
        }
        break;
      case CallStateEnum.ENDED:
      case CallStateEnum.FAILED:
        print('❌ [CallState] Call ended/failed');
        if (state.cause != null) {
          print('   Cause: ${state.cause}');
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

  @override
  void onNewCall(Call call) {
    print('📲 [SipService] New incoming call');
    print('   Call ID: ${call.id}');
    print('   Remote identity: ${call.remote_identity ?? 'Unknown'}');
    
    _currentCall = call;
    _callNumber = call.remote_identity ?? 'Unknown';
    _setCallStatus(CallStatus.incoming);
    _setStatusMessage('Incoming call from ${call.remote_identity ?? 'Unknown'}');
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
        _setStatus(SipConnectionStatus.disconnected);
        _setStatusMessage('Unregistered');
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
        // Only change status if we were previously connected
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

  // Required implementations for SipUaHelperListener
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
        print('✅ [SipService] SIP helper stopped successfully');
      } catch (e) {
        print('❌ [SipService] Error stopping SIP helper: $e');
      }
    }
    super.dispose();
  }
}