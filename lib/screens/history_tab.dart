// lib/screens/history_tab.dart - Updated with Theme Support (Font removed)

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sip_service.dart';
import '../themes/app_themes.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<CallRecord> get _allCalls => CallHistoryManager.getAllCalls();
  List<CallRecord> get _incomingCalls => CallHistoryManager.getIncomingCalls();
  List<CallRecord> get _outgoingCalls => CallHistoryManager.getOutgoingCalls();
  List<CallRecord> get _missedCalls => CallHistoryManager.getMissedCalls();

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '';
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final baseWidth = 375.0;
            final scaleWidth = constraints.maxWidth / baseWidth;
            final scaleHeight = constraints.maxHeight / 667.0;
            final scale = (scaleWidth + scaleHeight) / 2;

            return Column(
              children: [
                Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  padding: EdgeInsets.fromLTRB(
                    16 * scale,
                    8 * scale,
                    16 * scale,
                    16 * scale,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getTabBarBackgroundColor(),
                      borderRadius: BorderRadius.circular(8 * scale),
                    ),
                    child: Row(
                      children: [
                        _buildTabButton('All', 0, scale),
                        _buildTabButton('Incoming', 1, scale),
                        _buildTabButton('Outgoing', 2, scale),
                        _buildTabButton('Missed', 3, scale),
                      ],
                    ),
                  ),
                ),

                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCallList(_allCalls, scale),
                      _buildCallList(_incomingCalls, scale),
                      _buildCallList(_outgoingCalls, scale),
                      _buildCallList(_missedCalls, scale),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Color _getTabBarBackgroundColor() {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFE5E5EA);
  }

  Widget _buildTabButton(String text, int index, double scale) {
    bool isSelected = _selectedTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _tabController.animateTo(index);
          });
        },
        child: Container(
          margin: EdgeInsets.all(2 * scale),
          padding: EdgeInsets.symmetric(vertical: 6 * scale),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? AppThemes.getCardBackgroundColor(context)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(6 * scale),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 2 * scale,
                        offset: Offset(0, 1 * scale),
                      ),
                    ]
                    : null,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  isSelected
                      ? Theme.of(context).colorScheme.onSurface
                      : AppThemes.getSecondaryTextColor(context),
              fontSize: 12 * scale,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCallList(List<CallRecord> calls, double scale) {
    if (calls.isEmpty) {
      return Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
             Icon(
  _getEmptyStateIcon(),
  size: 64 * scale,
  color: AppThemes.getSecondaryTextColor(context),
),
              SizedBox(height: 16 * scale),
              Text(
                _getEmptyStateTitle(),
                style: TextStyle(
                  fontSize: 18 * scale,
                  color: AppThemes.getSecondaryTextColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8 * scale),
              Text(
                _getEmptyStateSubtitle(),
                style: TextStyle(
                  fontSize: 14 * scale,
                  color: AppThemes.getSecondaryTextColor(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: calls.length,
        itemBuilder: (context, index) {
          final call = calls[index];
          return _buildCallTile(call, index == calls.length - 1, scale);
        },
      ),
    );
  }

  String _getEmptyStateTitle() {
    switch (_selectedTabIndex) {
      case 0:
        return 'No calls yet';
      case 1:
        return 'No incoming calls';
      case 2:
        return 'No outgoing calls';
      case 3:
        return 'No missed calls';
      default:
        return 'No calls yet';
    }
  }

  String _getEmptyStateSubtitle() {
    switch (_selectedTabIndex) {
      case 0:
        return 'Your call history will appear here';
      case 1:
        return 'Incoming calls will appear here';
      case 2:
        return 'Outgoing calls will appear here';
      case 3:
        return 'Missed calls will appear here';
      default:
        return 'Your call history will appear here';
    }
  }
  IconData _getEmptyStateIcon() {
  switch (_selectedTabIndex) {
    case 0:
      return CupertinoIcons.phone;
    case 1:
      return CupertinoIcons.arrow_down_left;
    case 2:
      return CupertinoIcons.arrow_up_right;
    case 3:
      return CupertinoIcons.phone_down;
    default:
      return CupertinoIcons.phone;
  }
}

  Widget _buildCallTile(CallRecord call, bool isLast, double scale) {
    return InkWell(
      onTap: () {
        _showCallDetails(call);
      },
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16 * scale,
              vertical: 12 * scale,
            ),
            child: Row(
              children: [
                Container(
                  width: 40 * scale,
                  height: 40 * scale,
                  decoration: BoxDecoration(
color: AppThemes.getSecondaryTextColor(context),                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child:
                        call.name != null
                            ? Text(
                              _getInitials(call.name),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16 * scale,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                            : Icon(
                              CupertinoIcons.person_fill,
                              color: Colors.white,
                              size: 20 * scale,
                            ),
                  ),
                ),

                SizedBox(width: 12 * scale),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getCallDirectionIcon(call.type),
                            color:
                                call.type == CallType.missed
                                    ? const Color(0xFFFF3B30)
                                    : AppThemes.getSecondaryTextColor(context),
                            size: 16 * scale,
                          ),
                          SizedBox(width: 6 * scale),
                          Expanded(
                            child: Text(
                              call.name ?? call.number,
                              style: TextStyle(
                                fontSize: 17 * scale,
                                fontWeight: FontWeight.w400,
                                color:
                                    call.type == CallType.missed
                                        ? const Color(0xFFFF3B30)
                                        : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (call.name != null) ...[
                        SizedBox(height: 2 * scale),
                        Text(
                          call.number,
                          style: TextStyle(
                            fontSize: 15 * scale,
                            color: AppThemes.getSecondaryTextColor(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatRelativeTime(call.timestamp),
                      style: TextStyle(
                        fontSize: 15 * scale,
                        color: AppThemes.getSecondaryTextColor(context),
                      ),
                    ),
                    if (call.duration != Duration.zero) ...[
                      SizedBox(height: 2 * scale),
                      Text(
                        _formatDuration(call.duration),
                        style: TextStyle(
                          fontSize: 13 * scale,
                          color: AppThemes.getSecondaryTextColor(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // iOS separator line
          if (!isLast)
            Container(
              height: 0.5,
              margin: EdgeInsets.only(left: 68 * scale),
color: AppThemes.getSecondaryTextColor(context),            ),
        ],
      ),
    );
  }

  IconData _getCallDirectionIcon(CallType type) {
    switch (type) {
      case CallType.incoming:
        return CupertinoIcons.arrow_down_left;
      case CallType.outgoing:
        return CupertinoIcons.arrow_up_right;
      case CallType.missed:
        return CupertinoIcons.arrow_down_left;
    }
  }

  void _showCallDetails(CallRecord call) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (BuildContext context) => CupertinoActionSheet(
            title: Text(
              call.name ?? call.number,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            message: Text(
              '${_formatTime(call.timestamp)} • ${_formatDuration(call.duration)}',
              style: TextStyle(color: AppThemes.getSecondaryTextColor(context)),
            ),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  // Make call
                  final sipService = Provider.of<SipService>(
                    context,
                    listen: false,
                  );
                  if (sipService.status == SipConnectionStatus.connected) {
                    sipService.makeCall(call.number);
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.phone,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Call',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteCallRecord(call);
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.delete, color: Color(0xFFFF3B30)),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Color(0xFFFF3B30))),
                  ],
                ),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              isDefaultAction: true,
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
    );
  }

  void _deleteCallRecord(CallRecord call) {
    setState(() {
      CallHistoryManager.deleteCall(call.id);
    });
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays >= 2) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays >= 1) {
      return 'Yesterday';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour =
        dateTime.hour == 0
            ? 12
            : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) {
      return 'No answer';
    }

    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}

// Enhanced CallRecord and CallHistoryManager
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

class CallHistoryManager {
  static final List<CallRecord> _callHistory = [];

  // Add a new call record
  static void addCall({
    required String number,
    String? name,
    required CallType type,
    required DateTime timestamp,
    Duration duration = Duration.zero,
  }) {
    final record = CallRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      number: number,
      name: name,
      type: type,
      timestamp: timestamp,
      duration: duration,
    );

    _callHistory.insert(0, record); // Insert at beginning for latest first

    // Keep only last 100 calls to prevent memory issues
    if (_callHistory.length > 100) {
      _callHistory.removeRange(100, _callHistory.length);
    }

    print('📱 [CallHistory] Added ${type.name} call: $number');
  }

  // Get all calls
  static List<CallRecord> getAllCalls() {
    return List.from(_callHistory);
  }

  // Get incoming calls
  static List<CallRecord> getIncomingCalls() {
    return _callHistory
        .where((call) => call.type == CallType.incoming)
        .toList();
  }

  // Get outgoing calls
  static List<CallRecord> getOutgoingCalls() {
    return _callHistory
        .where((call) => call.type == CallType.outgoing)
        .toList();
  }

  // Get missed calls
  static List<CallRecord> getMissedCalls() {
    return _callHistory.where((call) => call.type == CallType.missed).toList();
  }

  // Delete a specific call
  static void deleteCall(String id) {
    _callHistory.removeWhere((call) => call.id == id);
    print('📱 [CallHistory] Deleted call: $id');
  }

  // Clear all calls
  static void clearHistory() {
    _callHistory.clear();
    print('📱 [CallHistory] Cleared all call history');
  }

  // Update call duration (for when call ends)
  static void updateCallDuration(String number, Duration duration) {
    final index = _callHistory.indexWhere(
      (call) =>
          call.number == number &&
          call.duration == Duration.zero &&
          DateTime.now().difference(call.timestamp).inMinutes <
              5, // Recent call
    );

    if (index != -1) {
      final oldCall = _callHistory[index];
      final updatedCall = CallRecord(
        id: oldCall.id,
        number: oldCall.number,
        name: oldCall.name,
        type: oldCall.type,
        timestamp: oldCall.timestamp,
        duration: duration,
      );

      _callHistory[index] = updatedCall;
      print(
        '📱 [CallHistory] Updated call duration: $number -> ${duration.inSeconds}s',
      );
    }
  }

  // Mark call as missed
  static void markAsMissed(String number) {
    final index = _callHistory.indexWhere(
      (call) =>
          call.number == number &&
          call.type == CallType.incoming &&
          DateTime.now().difference(call.timestamp).inMinutes <
              5, // Recent call
    );

    if (index != -1) {
      final oldCall = _callHistory[index];
      final missedCall = CallRecord(
        id: oldCall.id,
        number: oldCall.number,
        name: oldCall.name,
        type: CallType.missed,
        timestamp: oldCall.timestamp,
        duration: Duration.zero,
      );

      _callHistory[index] = missedCall;
      print('📱 [CallHistory] Marked call as missed: $number');
    }
  }
}