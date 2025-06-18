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
  List<CallRecord> get _missedCalls => _callHistory.where((call) => call.type == CallType.missed).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar - iOS style with smaller width
        Container(
          margin: const EdgeInsets.all(16),
          child: Center(
            child: Container(
              width: 180, // Fixed small width like iOS
              height: 32, // Compact height
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF0077F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(2),
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.black54,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Missed'),
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
              _buildCallList(_allCalls),
              _buildCallList(_missedCalls),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCallList(List<CallRecord> calls) {
    if (calls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.call_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No calls yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your call history will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: calls.length,
      itemBuilder: (context, index) {
        final call = calls[index];
        return _buildCallTile(call);
      },
    );
  }

  Widget _buildCallTile(CallRecord call) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: call.type == CallType.missed
            ? Border.all(color: Colors.red.withOpacity(0.2))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: _getCallTypeColor(call.type).withOpacity(0.1),
              radius: 24,
              child: Text(
                call.avatar,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _getCallTypeColor(call.type),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  _getCallTypeIcon(call.type),
                  color: Colors.white,
                  size: 8,
                ),
              ),
            ),
          ],
        ),
        title: Text(
          call.name ?? call.number,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: call.type == CallType.missed ? Colors.red : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (call.name != null) ...[
              Text(
                call.number,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
            ],
            Text(
              '${_formatTime(call.timestamp)} • ${_formatDuration(call.duration)}',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Consumer<SipService>(
          builder: (context, sipService, child) {
            return Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: sipService.status == SipConnectionStatus.connected
                    ? const LinearGradient(
                        begin: Alignment(-0.05, -1.0),
                        end: Alignment(0.05, 1.0),
                        colors: [Color(0xFF1501FF), Color(0xFF00A3FF)],
                      )
                    : null,
                color: sipService.status != SipConnectionStatus.connected
                    ? Colors.grey.shade300
                    : null,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: sipService.status == SipConnectionStatus.connected
                      ? () => sipService.makeCall(call.number)
                      : null,
                  child: Icon(
                    Icons.call,
                    color: sipService.status == SipConnectionStatus.connected
                        ? Colors.white
                        : Colors.grey.shade500,
                    size: 18,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getCallTypeColor(CallType type) {
    switch (type) {
      case CallType.incoming:
        return Colors.green;
      case CallType.outgoing:
        return Colors.blue;
      case CallType.missed:
        return Colors.red;
    }
  }

  IconData _getCallTypeIcon(CallType type) {
    switch (type) {
      case CallType.incoming:
        return Icons.call_received;
      case CallType.outgoing:
        return Icons.call_made;
      case CallType.missed:
        return Icons.call_missed;
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour == 0 ? 12 : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
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