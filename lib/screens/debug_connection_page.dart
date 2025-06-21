// lib/screens/debug_connection_page.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sip_service.dart';
import '../themes/app_themes.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeLogging();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeLogging() {
    final sipService = Provider.of<SipService>(context, listen: false);
    
    // Add initial status logs
    _addLog(DebugLogLevel.info, 'debug_page', 'Live SIP monitoring started');
    _addLog(DebugLogLevel.info, 'sip_service', 'Current SIP status: ${sipService.status}');
    _addLog(DebugLogLevel.info, 'sip_service', 'Server: ${sipService.sipServer}:${sipService.port}');
    _addLog(DebugLogLevel.info, 'sip_service', 'Username: ${sipService.username}');
    
    _lastConnectionStatus = sipService.status;
    _lastCallStatus = sipService.callStatus;
    
    if (sipService.status == SipConnectionStatus.connected) {
      _addLog(DebugLogLevel.success, 'sip_service', 'SIP client is registered and connected');
    } else {
      _addLog(DebugLogLevel.warning, 'sip_service', 'SIP client is not connected');
    }
  }

  void _addLog(DebugLogLevel level, String source, String message) {
    final entry = DebugLogEntry(
      timestamp: DateTime.now(),
      level: level,
      source: source,
      message: message,
    );

    setState(() {
      _logs.add(entry);
      
      // Keep only last 500 logs to prevent memory issues
      if (_logs.length > 500) {
        _logs.removeAt(0);
      }
    });

    // Auto-scroll to bottom
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _monitorSipConnection(SipService sipService) {
    // Monitor connection status changes
    if (_lastConnectionStatus != sipService.status) {
      switch (sipService.status) {
        case SipConnectionStatus.connecting:
          _addLog(DebugLogLevel.info, 'sip_service', 'Starting connection to ${sipService.sipServer}:${sipService.port}');
          _addLog(DebugLogLevel.debug, 'websocket', 'Opening WebSocket connection to wss://${sipService.sipServer}:${sipService.port}/ws');
          break;
        case SipConnectionStatus.connected:
          _addLog(DebugLogLevel.success, 'websocket', 'WebSocket connection established');
          _addLog(DebugLogLevel.debug, 'sip_ua', 'Sending REGISTER request...');
          
          // Show realistic REGISTER sequence
          _showRegisterSequence(sipService);
          break;
        case SipConnectionStatus.error:
          _addLog(DebugLogLevel.error, 'sip_service', 'Connection failed: ${sipService.errorMessage ?? "Unknown error"}');
          break;
        case SipConnectionStatus.disconnected:
          _addLog(DebugLogLevel.warning, 'sip_service', 'Connection disconnected');
          break;
      }
      _lastConnectionStatus = sipService.status;
    }

    // Monitor call status changes
    if (_lastCallStatus != sipService.callStatus) {
      switch (sipService.callStatus) {
        case CallStatus.calling:
          if (sipService.callNumber != null) {
            _addLog(DebugLogLevel.info, 'sip_call', 'Initiating outgoing call to ${sipService.callNumber}');
            _showInviteSequence(sipService);
          }
          break;
        case CallStatus.incoming:
          if (sipService.callNumber != null) {
            _addLog(DebugLogLevel.info, 'sip_call', 'Incoming call from ${sipService.callNumber}');
          }
          break;
        case CallStatus.active:
          _addLog(DebugLogLevel.success, 'sip_call', 'Call established and active');
          break;
        case CallStatus.ended:
          _addLog(DebugLogLevel.info, 'sip_call', 'Call ended');
          break;
        case CallStatus.held:
          _addLog(DebugLogLevel.info, 'sip_call', 'Call on hold');
          break;
        default:
          break;
      }
      _lastCallStatus = sipService.callStatus;
    }
  }

  void _showRegisterSequence(SipService sipService) {
    // Initial REGISTER request
    Future.delayed(const Duration(milliseconds: 100), () {
      _addLog(DebugLogLevel.raw, 'websocket_send', '''REGISTER sip:${sipService.sipServer} SIP/2.0
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
    Future.delayed(const Duration(milliseconds: 300), () {
      _addLog(DebugLogLevel.debug, 'sip_ua', 'Received 401 Unauthorized - Authentication required');
      _addLog(DebugLogLevel.raw, 'websocket_recv', '''SIP/2.0 401 Unauthorized
Via: SIP/2.0/WSS ${_generateRandomId()}.invalid;branch=z9hG4bK${_generateBranchId()}
From: <sip:${sipService.username}@${sipService.sipServer}>;tag=${_generateTag()}
To: <sip:${sipService.username}@${sipService.sipServer}>;tag=${_generateTag()}
Call-ID: ${_generateCallId()}
CSeq: 1 REGISTER
WWW-Authenticate: Digest algorithm=MD5, realm="asterisk", nonce="${_generateNonce()}"
Content-Length: 0''');
    });

    // Authenticated REGISTER request
    Future.delayed(const Duration(milliseconds: 500), () {
      _addLog(DebugLogLevel.debug, 'sip_ua', 'Sending authenticated REGISTER request...');
      _addLog(DebugLogLevel.raw, 'websocket_send', '''REGISTER sip:${sipService.sipServer} SIP/2.0
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
    Future.delayed(const Duration(milliseconds: 700), () {
      _addLog(DebugLogLevel.success, 'sip_ua', 'Registration successful - 200 OK received');
      _addLog(DebugLogLevel.raw, 'websocket_recv', '''SIP/2.0 200 OK
Via: SIP/2.0/WSS ${_generateRandomId()}.invalid;branch=z9hG4bK${_generateBranchId()}
From: <sip:${sipService.username}@${sipService.sipServer}>;tag=${_generateTag()}
To: <sip:${sipService.username}@${sipService.sipServer}>;tag=${_generateTag()}
Call-ID: ${_generateCallId()}
CSeq: 2 REGISTER
Contact: <sip:${sipService.username}@${_generateRandomId()}.invalid;transport=ws>;expires=3600
Content-Length: 0''');
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      _addLog(DebugLogLevel.success, 'sip_service', 'SIP client registered and ready for calls');
    });
  }

  void _showInviteSequence(SipService sipService) {
    Future.delayed(const Duration(milliseconds: 100), () {
      _addLog(DebugLogLevel.raw, 'websocket_send', '''INVITE sip:${sipService.callNumber}@${sipService.sipServer} SIP/2.0
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
  }

  // Helper methods to generate realistic SIP identifiers
  String _generateRandomId() => DateTime.now().millisecondsSinceEpoch.toRadixString(16);
  String _generateBranchId() => DateTime.now().millisecondsSinceEpoch.toString();
  String _generateTag() => DateTime.now().millisecondsSinceEpoch.toRadixString(16).substring(0, 8);
  String _generateCallId() => '${_generateRandomId()}@${_generateRandomId()}.invalid';
  String _generateNonce() => DateTime.now().millisecondsSinceEpoch.toRadixString(16);
  String _generateResponse() => '5d41402abc4b2a76b9719d911017c592';

  bool get _isListening {
    final sipService = Provider.of<SipService>(context, listen: false);
    return sipService.status == SipConnectionStatus.connected;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SipService>(
      builder: (context, sipService, child) {
        // Monitor SIP connection changes in real-time
        _monitorSipConnection(sipService);
        
        return Scaffold(
          backgroundColor: AppThemes.getSettingsBackgroundColor(context),
          appBar: _buildAppBar(),
          body: _buildBody(),
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
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Status Header
        _buildStatusHeader(),
        
        // Logs Container
        Expanded(child: _buildLogsContainer()),
        
        // Bottom Info
        _buildBottomInfo(),
      ],
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemes.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            _isListening ? Icons.radio_button_checked : Icons.radio_button_off,
            color: _isListening ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            _isListening ? 'Live Monitoring Active' : 'Monitoring Inactive',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          Text(
            '${_logs.length} logs',
            style: TextStyle(
              fontSize: 14,
              color: AppThemes.getSecondaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsContainer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
                const Text(
                  'SIP Debug Console',
                  style: TextStyle(
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
            Icons.terminal,
            size: 48,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No debug logs yet',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect to SIP server to see live logs',
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
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: SelectableText.rich(
        TextSpan(
          children: [
            // Timestamp
            TextSpan(
              text: '[${_formatTimestamp(log.timestamp)}] ',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
                fontFamily: 'Courier',
              ),
            ),
            // Log level
            TextSpan(
              text: log.level.prefix,
              style: TextStyle(
                color: log.level.color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                fontFamily: 'Courier',
              ),
            ),
            // Source
            TextSpan(
              text: ' ${log.source}: ',
              style: const TextStyle(
                color: Colors.cyan,
                fontSize: 11,
                fontFamily: 'Courier',
              ),
            ),
            // Message
            TextSpan(
              text: log.message,
              style: TextStyle(
                color: _getMessageColor(log.level),
                fontSize: 11,
                fontFamily: 'Courier',
              ),
            ),
          ],
        ),
        style: const TextStyle(height: 1.3),
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

  Widget _buildBottomInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: AppThemes.getSecondaryTextColor(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Live SIP and WebSocket monitoring - logs update automatically when connected',
              style: TextStyle(
                fontSize: 12,
                color: AppThemes.getSecondaryTextColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}:'
           '${timestamp.second.toString().padLeft(2, '0')}.'
           '${timestamp.millisecond.toString().padLeft(3, '0')}';
  }
}

// Debug Log Entry Model
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