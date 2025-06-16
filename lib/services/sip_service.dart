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
  
  // SIP Configuration
  String _sipServer = '';
  String _username = '';
  String _password = '';
  String _domain = '';
  int _port = 5060;
  
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

  Future<void> initialize() async {
    try {
      _setStatusMessage('Initializing SIP client...');
      
      _helper = SIPUAHelper();
      _helper!.addSipUaHelperListener(this);
      
      // Load saved settings
      await _loadSettings();
      
      _setStatusMessage('SIP client initialized. Configure settings to connect.');
    } catch (e) {
      _setError('Failed to initialize SIP client: $e');
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _sipServer = prefs.getString('sip_server') ?? '';
    _username = prefs.getString('sip_username') ?? '';
    _password = prefs.getString('sip_password') ?? '';
    _domain = prefs.getString('sip_domain') ?? '';
    _port = prefs.getInt('sip_port') ?? 5060;
    notifyListeners();
  }

  Future<void> saveSettings(String server, String username, String password, String domain, int port) async {
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
    
    notifyListeners();
  }

  Future<bool> register() async {
    if (_helper == null) {
      _setError('SIP client not initialized');
      return false;
    }

    if (_sipServer.isEmpty || _username.isEmpty || _password.isEmpty) {
      _setError('Please configure SIP settings first');
      return false;
    }

    try {
      _setStatus(SipConnectionStatus.connecting);
      _setStatusMessage('Connecting to $_sipServer...');
      
      // Create SIP UA settings
      final settings = UaSettings();
      
      // WebSocket URL - adjust based on your Asterisk setup
      settings.webSocketUrl = 'ws://$_sipServer:$_port/ws';
      settings.uri = 'sip:$_username@${_domain.isEmpty ? _sipServer : _domain}';
      settings.authorizationUser = _username;
      settings.password = _password;
      settings.displayName = _username;
      settings.userAgent = 'DashCall 1.0';
      settings.dtmfMode = DtmfMode.RFC2833;
      settings.register = true;
      
      await _helper!.start(settings);
      return true;
    } catch (e) {
      _setError('Registration failed: $e');
      _setStatus(SipConnectionStatus.error);
      return false;
    }
  }

  Future<void> unregister() async {
    if (_helper != null) {
      try {
        _helper!.stop();
        _setStatus(SipConnectionStatus.disconnected);
        _setStatusMessage('Disconnected');
      } catch (e) {
        _setError('Failed to unregister: $e');
      }
    }
  }

  Future<bool> makeCall(String phoneNumber) async {
    if (_helper == null || _status != SipConnectionStatus.connected) {
      _setError('Not connected to SIP server');
      return false;
    }

    if (phoneNumber.isEmpty) {
      _setError('Please enter a phone number');
      return false;
    }

    try {
      _setStatusMessage('Calling $phoneNumber...');
      _callNumber = phoneNumber;
      _callStartTime = DateTime.now();
      
      // Make call - using correct API
      final callOptions = _helper!.buildCallOptions(false); // false = voice only
      final call = await _helper!.call(phoneNumber, customOptions: callOptions);
      
      if (call != null) {
        _currentCall = call as Call?;
        _setCallStatus(CallStatus.calling);
        return true;
      } else {
        _setError('Failed to initiate call');
        return false;
      }
    } catch (e) {
      _setError('Failed to make call: $e');
      return false;
    }
  }

  Future<void> answerCall() async {
    if (_currentCall != null) {
      try {
        final callOptions = _helper!.buildCallOptions(false);
        _currentCall!.answer(callOptions);
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
    _currentCall = call;
    
    switch (state.state) {
      case CallStateEnum.CALL_INITIATION:
        _setCallStatus(CallStatus.calling);
        _setStatusMessage('Initiating call...');
        break;
      case CallStateEnum.PROGRESS:
        _setStatusMessage('Call in progress...');
        break;
      case CallStateEnum.ACCEPTED:
      case CallStateEnum.CONFIRMED:
        _setCallStatus(CallStatus.active);
        _setStatusMessage('Call connected');
        if (_callStartTime == null) {
          _callStartTime = DateTime.now();
        }
        break;
      case CallStateEnum.ENDED:
      case CallStateEnum.FAILED:
        _endCall();
        break;
      case CallStateEnum.HOLD:
        _setCallStatus(CallStatus.held);
        break;
      case CallStateEnum.UNHOLD:
        _setCallStatus(CallStatus.active);
        break;
      case CallStateEnum.MUTED:
      case CallStateEnum.UNMUTED:
        // Handle mute states if needed
        break;
      case CallStateEnum.STREAM:
        // Handle media stream
        break;
      case CallStateEnum.REFER:
        // Handle call transfer
        break;
      case CallStateEnum.NONE:
        // TODO: Handle this case.
        throw UnimplementedError();
      case CallStateEnum.CONNECTING:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  @override
  void onNewCall(Call call) {
    _currentCall = call;
    _callNumber = call.remote_identity;
    _setCallStatus(CallStatus.incoming);
    _setStatusMessage('Incoming call from ${call.remote_identity}');
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    switch (state.state) {
      case RegistrationStateEnum.REGISTERED:
        _setStatus(SipConnectionStatus.connected);
        _setStatusMessage('Registered successfully');
        break;
      case RegistrationStateEnum.UNREGISTERED:
        _setStatus(SipConnectionStatus.disconnected);
        _setStatusMessage('Unregistered');
        break;
      case RegistrationStateEnum.REGISTRATION_FAILED:
        _setStatus(SipConnectionStatus.error);
        _setError('Registration failed: ${state.cause ?? 'Unknown error'}');
        break;
      case null:
        _setStatusMessage('Registration state unknown');
        break;
      case RegistrationStateEnum.NONE:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  @override
  void transportStateChanged(TransportState state) {
    switch (state.state) {
      case TransportStateEnum.CONNECTED:
        _setStatusMessage('Transport connected');
        break;
      case TransportStateEnum.CONNECTING:
        _setStatusMessage('Connecting...');
        break;
      case TransportStateEnum.DISCONNECTED:
        if (_status == SipConnectionStatus.connected) {
          _setStatus(SipConnectionStatus.disconnected);
          _setStatusMessage('Connection lost');
        }
        break;
      case TransportStateEnum.NONE:
        // Handle no transport state
        break;
    }
  }

  // Required implementations for SipUaHelperListener
  @override
  void onNewMessage(SIPMessageRequest msg) {
    // Handle incoming SIP messages if needed
    // Using toString() since 'method' property might not exist
    print('New SIP message received: ${msg.toString()}');
  }

  @override
  void onNewNotify(Notify ntf) {
    // Handle SIP notifications if needed
    // Using toString() since 'event' property might not exist
    print('New SIP notify received: ${ntf.toString()}');
  }

  @override
  void onNewReinvite(ReInvite reinvite) {
    // Handle call re-invitations if needed
    print('New re-invite received: ${reinvite.toString()}');
  }

  void _endCall() {
    _currentCall = null;
    _callNumber = null;
    _callStartTime = null;
    _setCallStatus(CallStatus.idle);
    _setStatusMessage('Call ended');
  }

  void _setStatus(SipConnectionStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setCallStatus(CallStatus status) {
    _callStatus = status;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _statusMessage = error;
    notifyListeners();
  }

  void _setStatusMessage(String message) {
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
    if (_helper != null) {
      _helper!.stop();
    }
    super.dispose();
  }
}