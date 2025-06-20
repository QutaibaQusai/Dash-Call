import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sip_service.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> with TickerProviderStateMixin {
  late TabController _tabController;

  // Sample call history data
  final List<CallRecord> _callHistory = [
    CallRecord(
      id: '1',
      number: '101',
      name: 'John Doe',
      type: CallType.outgoing,
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      duration: const Duration(minutes: 5, seconds: 23),
      avatar: '👤',
    ),
    CallRecord(
      id: '2',
      number: '102',
      name: 'Jane Smith',
      type: CallType.incoming,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      duration: const Duration(minutes: 12, seconds: 45),
      avatar: '👩',
    ),
    CallRecord(
      id: '3',
      number: '103',
      name: 'Mike Johnson',
      type: CallType.missed,
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      duration: Duration.zero,
      avatar: '👨',
    ),
    CallRecord(
      id: '4',
      number: '555-0123',
      name: null,
      type: CallType.outgoing,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      duration: const Duration(minutes: 2, seconds: 10),
      avatar: '📞',
    ),
    CallRecord(
      id: '5',
      number: '104',
      name: 'Sarah Wilson',
      type: CallType.missed,
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      duration: Duration.zero,
      avatar: '👩‍💼',
    ),
    CallRecord(
      id: '6',
      number: '105',
      name: 'David Brown',
      type: CallType.incoming,
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      duration: const Duration(minutes: 8, seconds: 30),
      avatar: '👨‍💻',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<CallRecord> get _allCalls => _callHistory;
  List<CallRecord> get _missedCalls =>
      _callHistory.where((call) => call.type == CallType.missed).toList();

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '';
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF2F2F7),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Proportional scaling system
            final baseWidth = 375.0; // iPhone SE reference
            final scaleWidth = constraints.maxWidth / baseWidth;
            final scaleHeight = constraints.maxHeight / 667.0;
            final scale = (scaleWidth + scaleHeight) / 2;

            return Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.fromLTRB(
                    16 * scale,
                    8 * scale,
                    16 * scale,
                    16 * scale,
                  ),
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E5EA),
                        borderRadius: BorderRadius.circular(8 * scale),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTabButton('All', 0, scale),
                          _buildTabButton('Missed', 1, scale),
                        ],
                      ),
                    ),
                  ),
                ),

                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCallList(_allCalls, scale),
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

  Widget _buildTabButton(String text, int index, double scale) {
    bool isSelected = _tabController.index == index;

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
            color: isSelected ? Colors.white : Colors.transparent,
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
              color: isSelected ? Colors.black : const Color(0xFF8E8E93),
              fontSize: 13 * scale,
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
        color: const Color(0xFFF2F2F7),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.phone,
                size: 64 * scale,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: 16 * scale),
              Text(
                'No calls yet',
                style: TextStyle(
                  fontSize: 18 * scale,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8 * scale),
              Text(
                'Your call history will appear here',
                style: TextStyle(
                  fontSize: 14 * scale,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.white,
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
                // Avatar with initials
                Container(
                  width: 40 * scale,
                  height: 40 * scale,
                  decoration: const BoxDecoration(
                    color: Color(0xFFC6C6C8),
                    shape: BoxShape.circle,
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
                          // Call direction icon
                          Icon(
                            _getCallDirectionIcon(call.type),
                            color:
                                call.type == CallType.missed
                                    ? const Color(0xFFFF3B30)
                                    : const Color(0xFF8E8E93),
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
                                        : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (call.name != null) ...[
                        SizedBox(height: 2 * scale),
                        Text(
                          'Number',
                          style: TextStyle(
                            fontSize: 15 * scale,
                            color: const Color(0xFF8E8E93),
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
                        color: const Color(0xFF8E8E93),
                      ),
                    ),
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
              color: const Color(0xFFC6C6C8),
            ),
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
            title: Text(call.name ?? call.number),
            message: Text(
              '${_formatTime(call.timestamp)} • ${_formatDuration(call.duration)}',
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
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.phone, color: Color(0xFF007AFF)),
                    SizedBox(width: 8),
                    Text('Call', style: TextStyle(color: Color(0xFF007AFF))),
                  ],
                ),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              isDefaultAction: true,
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF007AFF)),
              ),
            ),
          ),
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays >= 1) {
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

enum CallType { incoming, outgoing, missed }

class CallRecord {
  final String id;
  final String number;
  final String? name;
  final CallType type;
  final DateTime timestamp;
  final Duration duration;
  final String avatar;

  CallRecord({
    required this.id,
    required this.number,
    this.name,
    required this.type,
    required this.timestamp,
    required this.duration,
    required this.avatar,
  });
}
