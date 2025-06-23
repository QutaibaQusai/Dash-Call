// lib/screens/history_tab.dart - Updated with Shared Action Sheet

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/multi_account_manager.dart';
import '../services/sip_service.dart';
import '../services/call_history_manager.dart';
import '../services/call_history_database.dart';
import '../themes/app_themes.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/shared_contact_action_sheet.dart'; // NEW: Import shared component

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<CallRecord> _allCalls = [];
  List<CallRecord> _incomingCalls = [];
  List<CallRecord> _outgoingCalls = [];
  List<CallRecord> _missedCalls = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    _loadCallHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = _calculateScale(constraints);

            return Column(
              children: [
                SizedBox(height: 16 * scale),

                // Search bar
                SearchBarWidget(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  hintText: 'Search',
                ),

                SizedBox(height: 12 * scale),

                // Tab bar
                _buildTabBar(scale),

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

  /// Calculate responsive scale
  double _calculateScale(BoxConstraints constraints) {
    const baseWidth = 375.0;
    const baseHeight = 667.0;
    final scaleWidth = constraints.maxWidth / baseWidth;
    final scaleHeight = constraints.maxHeight / baseHeight;
    return (scaleWidth + scaleHeight) / 2;
  }

  /// Build tab bar
  Widget _buildTabBar(double scale) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.fromLTRB(16 * scale, 0, 16 * scale, 8 * scale),
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
    );
  }

  /// Build individual tab button
  Widget _buildTabButton(String text, int index, double scale) {
    final isSelected = _selectedTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _tabController.animateTo(index),
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

  /// Build call list for each tab
  Widget _buildCallList(List<CallRecord> calls, double scale) {
    if (_isLoading && calls.isEmpty) {
      return _buildLoadingState();
    }

    if (calls.isEmpty) {
      return _buildEmptyState(scale);
    }

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: calls.length,
        itemBuilder: (context, index) {
          final call = calls[index];
          final isLast = index == calls.length - 1;
          return _buildCallTile(call, isLast, scale);
        },
      ),
    );
  }

  /// Build loading state
  Widget _buildLoadingState() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState(double scale) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20 * scale),
              decoration: BoxDecoration(
                color: _getEmptyStateIconBackgroundColor(),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getEmptyStateIcon(),
                size: 44 * scale,
                color: _getEmptyStateIconColor(),
              ),
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

  /// Build individual call tile
  Widget _buildCallTile(CallRecord call, bool isLast, double scale) {
    return InkWell(
      onTap: () => _showCallDetails(call), // UPDATED: Use shared sheet
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16 * scale,
              vertical: 12 * scale,
            ),
            child: Row(
              children: [
                // Contact avatar
                _buildContactAvatar(call, scale),
                SizedBox(width: 12 * scale),

                // Call info
                Expanded(child: _buildCallInfo(call, scale)),

                // Time and duration
                _buildTimeInfo(call, scale),
              ],
            ),
          ),

          // Divider
          if (!isLast) _buildDivider(scale),
        ],
      ),
    );
  }

  /// Build contact avatar
  Widget _buildContactAvatar(CallRecord call, double scale) {
    return Container(
      width: 40 * scale,
      height: 40 * scale,
      decoration: BoxDecoration(
        color: AppThemes.getSecondaryTextColor(context),
        shape: BoxShape.circle,
      ),
      child: Center(
        child:
            call.name != null
                ? Text(
                  _getInitials(call.name!),
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
    );
  }

  /// Build call information
  Widget _buildCallInfo(CallRecord call, double scale) {
    final isMissed = call.type == CallType.missed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _getCallDirectionIcon(call.type),
              color:
                  isMissed
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
                      isMissed
                          ? const Color(0xFFFF3B30)
                          : Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  /// Build time information
  Widget _buildTimeInfo(CallRecord call, double scale) {
    return Column(
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
    );
  }

  /// Build divider
  Widget _buildDivider(double scale) {
    return Container(
      height: 0.5,
      margin: EdgeInsets.only(left: 68 * scale),
      color: AppThemes.getDividerColor(context),
    );
  }

  // UPDATED: Use shared action sheet helper
  void _showCallDetails(CallRecord call) {
    ContactActionSheetHelper.show(
      context: context,
      displayName: call.name ?? call.number,
      phoneNumber: call.number,
      showDeleteAction: true, // History items have delete action
      onDelete: () => _deleteCallRecord(call),
      callTimestamp: call.timestamp,
      callDuration: call.duration,
    );
  }

  /// Load call history from database
  Future<void> _loadCallHistory() async {
    setState(() => _isLoading = true);

    try {
      final allCalls = await CallHistoryManager.getAllCalls();
      final incomingCalls = await CallHistoryManager.getIncomingCalls();
      final outgoingCalls = await CallHistoryManager.getOutgoingCalls();
      final missedCalls = await CallHistoryManager.getMissedCalls();

      setState(() {
        _allCalls = allCalls;
        _incomingCalls = incomingCalls;
        _outgoingCalls = outgoingCalls;
        _missedCalls = missedCalls;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ [HistoryTab] Failed to load call history: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Search calls based on query
  Future<void> _searchCalls(String query) async {
    if (query.isEmpty) {
      await _loadCallHistory();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final searchResults = await CallHistoryManager.searchCalls(query);

      setState(() {
        _allCalls = searchResults;
        _incomingCalls =
            searchResults
                .where((call) => call.type == CallType.incoming)
                .toList();
        _outgoingCalls =
            searchResults
                .where((call) => call.type == CallType.outgoing)
                .toList();
        _missedCalls =
            searchResults
                .where((call) => call.type == CallType.missed)
                .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('❌ [HistoryTab] Failed to search calls: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Handle search query change
  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);

    // Debounce search
    Future.delayed(Duration(milliseconds: 300), () {
      if (_searchQuery == value) {
        _searchCalls(value);
      }
    });
  }

  /// Delete call record
  Future<void> _deleteCallRecord(CallRecord call) async {
    await CallHistoryManager.deleteCall(call.id);

    // Refresh the UI
    if (_searchQuery.isNotEmpty) {
      await _searchCalls(_searchQuery);
    } else {
      await _loadCallHistory();
    }
  }

  // Helper methods
  Color _getTabBarBackgroundColor() {
    return Theme.of(context).brightness == Brightness.dark
        ? Color(0xFF2C2C2E)
        : Color(0xFFE5E5EA);
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    return name[0].toUpperCase();
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

  String _getEmptyStateTitle() {
    if (_searchQuery.isNotEmpty) return 'No results found';

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
    if (_searchQuery.isNotEmpty) return 'Try searching for something else';

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
    if (_searchQuery.isNotEmpty) return CupertinoIcons.search;

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

  Color _getEmptyStateIconColor() {
    if (_searchQuery.isNotEmpty) return Colors.orange;

    switch (_selectedTabIndex) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Color _getEmptyStateIconBackgroundColor() {
    return _getEmptyStateIconColor().withOpacity(0.1);
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

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) return 'No answer';

    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}