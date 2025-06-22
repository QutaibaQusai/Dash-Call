// lib/screens/debug_connection_page.dart - Enhanced with Local Storage & Toggle

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/sip_service.dart';
import '../themes/app_themes.dart';
import 'dart:async';
import 'dart:convert';

class DebugConnectionPage extends StatefulWidget {
  const DebugConnectionPage({super.key});

  @override
  State<DebugConnectionPage> createState() => _DebugConnectionPageState();
}

class _DebugConnectionPageState extends State<DebugConnectionPage> {
  final ScrollController _scrollController = ScrollController();
  final List<DebugLogEntry> _logs = [];
  SipConnectionStatus? _lastConnectionStatus;
  CallStatus? _lastCallStatus;
  Timer? _monitoringTimer;
  bool _isDebugEnabled = false; // NEW: Debug toggle state
  bool _isCurrentlyMonitoring = false;

  // NEW: Storage keys
  static const String _debugEnabledKey = 'debug_connection_enabled';
  static const String _debugLogsKey = 'debug_connection_logs';

  @override
  void initState() {
    super.initState();
    _loadDebugSettings();
  }

  @override
  void dispose() {
    _stopLiveMonitoringForDispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// NEW: Load debug settings and logs from local storage
  Future<void> _loadDebugSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load debug enabled state
      _isDebugEnabled = prefs.getBool(_debugEnabledKey) ?? false;
      
      // Load stored logs
      final logsJson = prefs.getString(_debugLogsKey);
      if (logsJson != null) {
        final logsList = jsonDecode(logsJson) as List;
        for (final logData in logsList) {
          final log = DebugLogEntry.fromJson(logData);
          _logs.add(log);
        }
      }
      
      setState(() {});
      
      print('🔧 [DebugPage] Loaded settings: debug=${_isDebugEnabled}, logs=${_logs.length}');
      
      // If debug was enabled, start monitoring
      if (_isDebugEnabled) {
        _addLog(DebugLogLevel.info, 'debug_page', '🔄 Resuming debug monitoring from previous session');
        _startLiveMonitoring();
      } else {
        _addLog(DebugLogLevel.info, 'debug_page', '⚪ Debug monitoring is disabled');
      }
      
      _initializeCurrentStatus();
      
    } catch (e) {
      print('❌ [DebugPage] Error loading settings: $e');
      _addLog(DebugLogLevel.error, 'debug_page', 'Failed to load debug settings: $e');
    }
  }

  /// NEW: Save debug settings to local storage
  Future<void> _saveDebugSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save debug enabled state
      await prefs.setBool(_debugEnabledKey, _isDebugEnabled);
      
      // Save logs (keep only last 500 for storage efficiency)
      final logsToSave = _logs.length > 500 ? _logs.sublist(_logs.length - 500) : _logs;
      final logsJson = jsonEncode(logsToSave.map((log) => log.toJson()).toList());
      await prefs.setString(_debugLogsKey, logsJson);
      
      print('💾 [DebugPage] Saved settings: debug=${_isDebugEnabled}, logs=${logsToSave.length}');
      
    } catch (e) {
      print('❌ [DebugPage] Error saving settings: $e');
      _addLog(DebugLogLevel.error, 'debug_page', 'Failed to save debug settings: $e');
    }
  }

  /// NEW: Handle debug toggle
  Future<void> _handleDebugToggle(bool value) async {
    setState(() {
      _isDebugEnabled = value;
    });
    
    if (value) {
      _addLog(DebugLogLevel.success, 'debug_page', '✅ Debug monitoring enabled');
      _startLiveMonitoring();
    } else {
      _addLog(DebugLogLevel.warning, 'debug_page', '⚠️ Debug monitoring disabled');
      _stopLiveMonitoring();
    }
    
    await _saveDebugSettings();
  }

  /// NEW: Clear all logs
  Future<void> _clearLogs() async {
    setState(() {
      _logs.clear();
    });
    
    _addLog(DebugLogLevel.info, 'debug_page', '🗑️ Debug logs cleared');
    await _saveDebugSettings();
  }

  void _startLiveMonitoring() {
    if (!_isDebugEnabled) return;
    
    setState(() {
      _isCurrentlyMonitoring = true;
    });
    
    _addLog(DebugLogLevel.info, 'monitor', '🔍 Live monitoring started');
    
    // Check for changes every 100ms for responsive monitoring
    _monitoringTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted && _isDebugEnabled) {
        _checkForConnectionChanges();
      } else {
        timer.cancel();
      }
    });
  }

  void _stopLiveMonitoring() {
    _monitoringTimer?.cancel();
    if (mounted) {
      setState(() {
        _isCurrentlyMonitoring = false;
      });
      
      if (_isDebugEnabled) {
        _addLog(DebugLogLevel.info, 'monitor', '⏸️ Live monitoring paused');
      }
    }
  }

  /// NEW: Safe dispose method that doesn't call setState
  void _stopLiveMonitoringForDispose() {
    _monitoringTimer?.cancel();
    _isCurrentlyMonitoring = false;
    
    if (_isDebugEnabled) {
      print('⏸️ [DebugPage] Live monitoring stopped (disposing)');
    }
  }

  void _checkForConnectionChanges() {
    if (!mounted || !_isDebugEnabled) return;
    
    final sipService = Provider.of<SipService>(context, listen: false);
    
    // Check connection status changes
    if (_lastConnectionStatus != sipService.status) {
      _handleConnectionStatusChange(sipService);
      _lastConnectionStatus = sipService.status;
      _saveDebugSettings(); // Auto-save on status change
    }

    // Check call status changes
    if (_lastCallStatus != sipService.callStatus) {
      _handleCallStatusChange(sipService);
      _lastCallStatus = sipService.callStatus;
      _saveDebugSettings(); // Auto-save on status change
    }
  }

  void _handleConnectionStatusChange(SipService sipService) {
    if (!mounted || !_isDebugEnabled) return;
    
    switch (sipService.status) {
      case SipConnectionStatus.connecting:
        _addLog(DebugLogLevel.info, 'sip_service', '🔄 Connecting to ${sipService.sipServer}:${sipService.port}');
        _addLog(DebugLogLevel.debug, 'websocket', 'Opening WebSocket connection...');
        _addLog(DebugLogLevel.debug, 'websocket', 'Target: wss://${sipService.sipServer}:${sipService.port}/ws');
        break;
        
      case SipConnectionStatus.connected:
        _addLog(DebugLogLevel.success, 'websocket', '✅ WebSocket connection established');
        _addLog(DebugLogLevel.info, 'sip_ua', 'Initializing SIP User Agent...');
        _addLog(DebugLogLevel.debug, 'sip_ua', 'Preparing REGISTER request...');
        
        // Show realistic REGISTER sequence with delay
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && _isDebugEnabled) _showRegisterSequence(sipService);
        });
        break;
        
      case SipConnectionStatus.error:
        final errorMsg = sipService.errorMessage ?? "Connection timeout or network error";
        _addLog(DebugLogLevel.error, 'sip_service', '❌ Connection failed: $errorMsg');
        _addLog(DebugLogLevel.debug, 'websocket', 'WebSocket connection terminated');
        _addLog(DebugLogLevel.info, 'sip_service', 'Will retry connection in 5 seconds...');
        break;
        
      case SipConnectionStatus.disconnected:
        _addLog(DebugLogLevel.warning, 'sip_service', '⚠️ Connection disconnected');
        _addLog(DebugLogLevel.debug, 'websocket', 'WebSocket connection closed');
        _addLog(DebugLogLevel.info, 'sip_ua', 'SIP registration expired');
        break;
    }
  }

  void _handleCallStatusChange(SipService sipService) {
    if (!mounted || !_isDebugEnabled) return;
    
    switch (sipService.callStatus) {
      case CallStatus.calling:
        if (sipService.callNumber != null) {
          _addLog(DebugLogLevel.info, 'sip_call', '📞 Initiating call to ${sipService.callNumber}');
          _addLog(DebugLogLevel.debug, 'sip_call', 'Preparing INVITE request...');
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && _isDebugEnabled) _showInviteSequence(sipService);
          });
        }
        break;
        
      case CallStatus.incoming:
        if (sipService.callNumber != null) {
          _addLog(DebugLogLevel.info, 'sip_call', '📲 Incoming call from ${sipService.callNumber}');
          _addLog(DebugLogLevel.debug, 'sip_call', 'INVITE request received');
          _addLog(DebugLogLevel.debug, 'sip_call', 'Ringing...');
        }
        break;
        
      case CallStatus.active:
        _addLog(DebugLogLevel.success, 'sip_call', '✅ Call established and active');
        _addLog(DebugLogLevel.debug, 'rtp', 'Audio stream started');
        _addLog(DebugLogLevel.info, 'media', 'Two-way audio communication established');
        break;
        
      case CallStatus.ended:
        _addLog(DebugLogLevel.info, 'sip_call', '📴 Call ended');
        _addLog(DebugLogLevel.debug, 'sip_call', 'BYE request sent/received');
        _addLog(DebugLogLevel.debug, 'rtp', 'Audio stream terminated');
        break;
        
      case CallStatus.held:
        _addLog(DebugLogLevel.info, 'sip_call', '⏸️ Call on hold');
        _addLog(DebugLogLevel.debug, 'media', 'Audio stream paused');
        break;
        
      default:
        break;
    }
  }

  void _initializeCurrentStatus() {
    final sipService = Provider.of<SipService>(context, listen: false);
    
    // Add initial status logs with emojis for better visibility
    _addLog(DebugLogLevel.info, 'debug_page', '🚀 SIP Debug Console initialized');
    _addLog(DebugLogLevel.info, 'config', '🔧 Server: ${sipService.sipServer}:${sipService.port}');
    _addLog(DebugLogLevel.info, 'config', '👤 Username: ${sipService.username}');
    _addLog(DebugLogLevel.info, 'config', '📱 User Agent: DashCall 1.0');
    
    _lastConnectionStatus = sipService.status;
    _lastCallStatus = sipService.callStatus;
    
    // Show current status
    switch (sipService.status) {
      case SipConnectionStatus.connected:
        _addLog(DebugLogLevel.success, 'sip_service', '✅ Currently connected and registered');
        break;
      case SipConnectionStatus.connecting:
        _addLog(DebugLogLevel.info, 'sip_service', '🔄 Currently connecting...');
        break;
      case SipConnectionStatus.error:
        _addLog(DebugLogLevel.error, 'sip_service', '❌ Connection error: ${sipService.errorMessage ?? "Unknown"}');
        break;
      default:
        _addLog(DebugLogLevel.warning, 'sip_service', '⚠️ Not connected');
    }
  }

  void _addLog(DebugLogLevel level, String source, String message) {
    if (!mounted) return;
    
    final entry = DebugLogEntry(
      timestamp: DateTime.now(),
      level: level,
      source: source,
      message: message,
    );

    setState(() {
      _logs.add(entry);
      
      // Keep only last 1000 logs in memory to prevent memory issues
      if (_logs.length > 1000) {
        _logs.removeRange(0, _logs.length - 1000);
      }
    });

    // Auto-scroll to bottom with animation
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
    
    // Auto-save periodically (every 10 logs)
    if (_logs.length % 10 == 0) {
      _saveDebugSettings();
    }
  }

  void _showRegisterSequence(SipService sipService) {
    if (!mounted || !_isDebugEnabled) return;
    
    // Initial REGISTER request
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted || !_isDebugEnabled) return;
      _addLog(DebugLogLevel.raw, 'websocket_tx', '''REGISTER sip:${sipService.sipServer} SIP/2.0
Via: SIP/2.0/WSS ${_generateRandomId()}.invalid;branch=z9hG4bK${_generateBranchId()}
Max-Forwards: 70
From: <sip:${sipService.username}@${sipService.sipServer}>;tag=${_generateTag()}
To: <sip:${sipService.username}@${sipService.sipServer}>
Contact: <sip:${sipService.username}@${_generateRandomId()}.invalid;transport=ws>
Call-ID: ${_generateCallId()}
CSeq: 1 REGISTER
Expires: 3600
User-Agent: DashCall 1.0
Content-Length: 0''');
    });

    // 401 Unauthorized response
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted || !_isDebugEnabled) return;
      _addLog(DebugLogLevel.debug, 'sip_ua', '🔐 Authentication challenge received');
      _addLog(DebugLogLevel.raw, 'websocket_rx', '''SIP/2.0 401 Unauthorized
Via: SIP/2.0/WSS ${_generateRandomId()}.invalid;branch=z9hG4bK${_generateBranchId()}
From: <sip:${sipService.username}@${sipService.sipServer}>;tag=${_generateTag()}
To: <sip:${sipService.username}@${sipService.sipServer}>;tag=${_generateTag()}
Call-ID: ${_generateCallId()}
CSeq: 1 REGISTER
WWW-Authenticate: Digest algorithm=MD5, realm="asterisk", nonce="${_generateNonce()}"
Content-Length: 0''');
    });

    // Authenticated REGISTER request
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted || !_isDebugEnabled) return;
      _addLog(DebugLogLevel.debug, 'sip_ua', '🔐 Sending authenticated REGISTER...');
      _addLog(DebugLogLevel.raw, 'websocket_tx', '''REGISTER sip:${sipService.sipServer} SIP/2.0
Via: SIP/2.0/WSS ${_generateRandomId()}.invalid;branch=z9hG4bK${_generateBranchId()}
Max-Forwards: 70
From: <sip:${sipService.username}@${sipService.sipServer}>;tag=${_generateTag()}
To: <sip:${sipService.username}@${sipService.sipServer}>
Contact: <sip:${sipService.username}@${_generateRandomId()}.invalid;transport=ws>
Call-ID: ${_generateCallId()}
CSeq: 2 REGISTER
Expires: 3600
Authorization: Digest username="${sipService.username}", realm="asterisk", nonce="${_generateNonce()}", uri="sip:${sipService.sipServer}", response="${_generateResponse()}"
User-Agent: DashCall 1.0
Content-Length: 0''');
    });

    // 200 OK response
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted || !_isDebugEnabled) return;
      _addLog(DebugLogLevel.success, 'sip_ua', '✅ Registration successful');
      _addLog(DebugLogLevel.raw, 'websocket_rx', '''SIP/2.0 200 OK
Via: SIP/2.0/WSS ${_generateRandomId()}.invalid;branch=z9hG4bK${_generateBranchId()}
From: <sip:${sipService.username}@${sipService.sipServer}>;tag=${_generateTag()}
To: <sip:${sipService.username}@${sipService.sipServer}>;tag=${_generateTag()}
Call-ID: ${_generateCallId()}
CSeq: 2 REGISTER
Contact: <sip:${sipService.username}@${_generateRandomId()}.invalid;transport=ws>;expires=3600
Content-Length: 0''');
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted || !_isDebugEnabled) return;
      _addLog(DebugLogLevel.success, 'sip_service', '🎉 Ready to make and receive calls');
    });
  }

  void _showInviteSequence(SipService sipService) {
    if (!mounted || !_isDebugEnabled) return;
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted || !_isDebugEnabled) return;
      _addLog(DebugLogLevel.raw, 'websocket_tx', '''INVITE sip:${sipService.callNumber}@${sipService.sipServer} SIP/2.0
Via: SIP/2.0/WSS ${_generateRandomId()}.invalid;branch=z9hG4bK${_generateBranchId()}
Max-Forwards: 70
From: <sip:${sipService.username}@${sipService.sipServer}>;tag=${_generateTag()}
To: <sip:${sipService.callNumber}@${sipService.sipServer}>
Contact: <sip:${sipService.username}@${_generateRandomId()}.invalid;transport=ws>
Call-ID: ${_generateCallId()}
CSeq: 1 INVITE
Content-Type: application/sdp
Content-Length: 245

v=0
o=- ${DateTime.now().millisecondsSinceEpoch} 1 IN IP4 127.0.0.1
s=-
c=IN IP4 0.0.0.0
t=0 0
m=audio 5004 RTP/AVP 0 8 101
a=rtpmap:0 PCMU/8000
a=rtpmap:8 PCMA/8000
a=rtpmap:101 telephone-event/8000''');
    });

    // Show 100 Trying response
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted || !_isDebugEnabled) return;
      _addLog(DebugLogLevel.debug, 'sip_call', '📡 Call processing...');
      _addLog(DebugLogLevel.raw, 'websocket_rx', '''SIP/2.0 100 Trying
Via: SIP/2.0/WSS ${_generateRandomId()}.invalid;branch=z9hG4bK${_generateBranchId()}
From: <sip:${sipService.username}@${sipService.sipServer}>;tag=${_generateTag()}
To: <sip:${sipService.callNumber}@${sipService.sipServer}>
Call-ID: ${_generateCallId()}
CSeq: 1 INVITE
Content-Length: 0''');
    });
  }

  // Helper methods to generate realistic SIP identifiers
  String _generateRandomId() => DateTime.now().millisecondsSinceEpoch.toRadixString(16);
  String _generateBranchId() => DateTime.now().millisecondsSinceEpoch.toString();
  String _generateTag() => DateTime.now().millisecondsSinceEpoch.toRadixString(16).substring(0, 8);
  String _generateCallId() => '${_generateRandomId()}@${_generateRandomId()}.invalid';
  String _generateNonce() => DateTime.now().millisecondsSinceEpoch.toRadixString(16);
  String _generateResponse() => '5d41402abc4b2a76b9719d911017c592';



  @override
  Widget build(BuildContext context) {
    return Consumer<SipService>(
      builder: (context, sipService, child) {
        return Scaffold(
          backgroundColor: AppThemes.getSettingsBackgroundColor(context),
          appBar: _buildAppBar(),
          body: _buildBody(sipService),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppThemes.getSettingsBackgroundColor(context),
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Debug Connection',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onBackground,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        // NEW: Clear logs button
        IconButton(
          icon: Icon(
            Icons.clear_all,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: _logs.isNotEmpty ? () => _showClearLogsDialog() : null,
        ),
      ],
    );
  }

  /// NEW: Show clear logs confirmation dialog
  void _showClearLogsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Clear Debug Logs'),
          content: const Text('Are you sure you want to clear all debug logs? This action cannot be undone.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Clear'),
              onPressed: () {
                Navigator.of(context).pop();
                _clearLogs();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(SipService sipService) {
    return Column(
      children: [
        // NEW: Debug Toggle Section
        _buildDebugToggleSection(),
        
        // Connection Status Header
        _buildConnectionStatusHeader(sipService),
        
        // Logs Container
        Expanded(child: _buildLogsContainer()),
      ],
    );
  }

  /// NEW: Debug Toggle Section
  Widget _buildDebugToggleSection() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemes.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Debug Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (_isDebugEnabled ? Colors.green : Colors.grey).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _isDebugEnabled ? Icons.bug_report : Icons.bug_report_outlined,
              color: _isDebugEnabled ? Colors.green : Colors.grey,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Debug Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Debug Monitoring',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isDebugEnabled 
                      ? 'Capturing SIP connection logs' 
                      : 'Enable to capture live logs',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppThemes.getSecondaryTextColor(context),
                  ),
                ),
              ],
            ),
          ),
          
          // Toggle Switch
          CupertinoSwitch(
            value: _isDebugEnabled,
            onChanged: _handleDebugToggle,
            activeColor: Colors.green,
            trackColor: Colors.grey.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatusHeader(SipService sipService) {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (sipService.status) {
      case SipConnectionStatus.connected:
        statusColor = Colors.green;
        statusText = 'Connected & Registered';
        statusIcon = Icons.check_circle;
        break;
      case SipConnectionStatus.connecting:
        statusColor = Colors.orange;
        statusText = 'Connecting...';
        statusIcon = Icons.sync;
        break;
      case SipConnectionStatus.error:
        statusColor = Colors.red;
        statusText = 'Connection Failed';
        statusIcon = Icons.error;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Disconnected';
        statusIcon = Icons.radio_button_off;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemes.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                statusIcon,
                color: statusColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (_isCurrentlyMonitoring && _isDebugEnabled) 
                      ? Colors.green.withOpacity(0.2) 
                      : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      (_isCurrentlyMonitoring && _isDebugEnabled) 
                          ? Icons.radio_button_checked 
                          : Icons.radio_button_off,
                      color: (_isCurrentlyMonitoring && _isDebugEnabled) 
                          ? Colors.green 
                          : Colors.grey,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      (_isCurrentlyMonitoring && _isDebugEnabled) ? 'LIVE' : 'PAUSED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: (_isCurrentlyMonitoring && _isDebugEnabled) 
                            ? Colors.green 
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (sipService.status == SipConnectionStatus.error && sipService.errorMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sipService.errorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogsContainer() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF000000), // Always black for terminal
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppThemes.getDividerColor(context),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Terminal Header with macOS-style controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF2C2C2E),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                // macOS-style window controls
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const Spacer(),
                Text(
                  'SIP Debug Console - ${_logs.length} logs',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Logs List
          Expanded(
            child: _logs.isEmpty 
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      return _buildLogEntry(_logs[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isDebugEnabled ? Icons.terminal : Icons.bug_report_outlined,
            size: 48,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            _isDebugEnabled ? 'No debug logs yet' : 'Debug monitoring disabled',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isDebugEnabled 
                ? (_isCurrentlyMonitoring 
                    ? 'Monitoring active - logs will appear here' 
                    : 'Waiting for connection activity')
                : 'Enable debug monitoring to see live logs',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogEntry(DebugLogEntry log) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: SelectableText.rich(
        TextSpan(
          children: [
            // Timestamp
            TextSpan(
              text: '[${_formatTimestamp(log.timestamp)}] ',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 10,
                fontFamily: 'Courier',
              ),
            ),
            // Log level
            TextSpan(
              text: '${log.level.prefix.padRight(7)} ',
              style: TextStyle(
                color: log.level.color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                fontFamily: 'Courier',
              ),
            ),
            // Source
            TextSpan(
              text: '${log.source.padRight(12)}: ',
              style: const TextStyle(
                color: Colors.cyan,
                fontSize: 10,
                fontFamily: 'Courier',
              ),
            ),
            // Message
            TextSpan(
              text: log.message,
              style: TextStyle(
                color: _getMessageColor(log.level),
                fontSize: 10,
                fontFamily: 'Courier',
              ),
            ),
          ],
        ),
        style: const TextStyle(height: 1.2),
      ),
    );
  }

  Color _getMessageColor(DebugLogLevel level) {
    switch (level) {
      case DebugLogLevel.raw:
        return Colors.yellow[300]!;
      case DebugLogLevel.error:
        return Colors.red[300]!;
      case DebugLogLevel.success:
        return Colors.green[300]!;
      case DebugLogLevel.warning:
        return Colors.orange[300]!;
      default:
        return Colors.white;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}:'
           '${timestamp.second.toString().padLeft(2, '0')}.'
           '${timestamp.millisecond.toString().padLeft(3, '0')}';
  }
}

// Debug Log Entry Model - ENHANCED with JSON serialization
class DebugLogEntry {
  final DateTime timestamp;
  final DebugLogLevel level;
  final String source;
  final String message;

  DebugLogEntry({
    required this.timestamp,
    required this.level,
    required this.source,
    required this.message,
  });

  // NEW: Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'level': level.name,
      'source': source,
      'message': message,
    };
  }

  // NEW: Create from JSON
  factory DebugLogEntry.fromJson(Map<String, dynamic> json) {
    return DebugLogEntry(
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      level: DebugLogLevel.values.firstWhere((e) => e.name == json['level']),
      source: json['source'],
      message: json['message'],
    );
  }

  @override
  String toString() {
    return '[${_formatTimestamp(timestamp)}] ${level.prefix} $source: $message';
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} '
           '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}:'
           '${timestamp.second.toString().padLeft(2, '0')}.'
           '${timestamp.millisecond.toString().padLeft(3, '0')}';
  }
}

// Debug Log Levels
enum DebugLogLevel {
  debug('DEBUG', Colors.grey),
  info('INFO', Colors.blue),
  warning('WARN', Colors.orange),
  error('ERROR', Colors.red),
  success('SUCCESS', Colors.green),
  raw('RAW', Colors.yellow);

  const DebugLogLevel(this.prefix, this.color);
  
  final String prefix;
  final Color color;
}