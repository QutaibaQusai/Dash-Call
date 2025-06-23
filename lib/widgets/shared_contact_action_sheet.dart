// lib/widgets/shared_contact_action_sheet.dart - Reusable Action Sheet Component

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/multi_account_manager.dart';
import '../services/sip_service.dart';
import '../themes/app_themes.dart';

class SharedContactActionSheet extends StatelessWidget {
  final String displayName;
  final String phoneNumber;
  final bool showDeleteAction;
  final VoidCallback? onDelete;
  final DateTime? callTimestamp;
  final Duration? callDuration;

  const SharedContactActionSheet({
    super.key,
    required this.displayName,
    required this.phoneNumber,
    this.showDeleteAction = false,
    this.onDelete,
    this.callTimestamp,
    this.callDuration,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MultiAccountManager>(
      builder: (context, accountManager, child) {
        return CupertinoActionSheet(
          title: Text(
            displayName,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          message: Column(
            children: [
              // Phone number
              Text(
                phoneNumber,
                style: TextStyle(
                  color: AppThemes.getSecondaryTextColor(context),
                  fontSize: 14,
                ),
              ),
              
              // Call info (only for history items)
              if (callTimestamp != null && callDuration != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${_formatTime(callTimestamp!)} • ${_formatDuration(callDuration!)}',
                  style: TextStyle(
                    color: AppThemes.getSecondaryTextColor(context),
                    fontSize: 14,
                  ),
                ),
              ],
              
              const SizedBox(height: 8),
              
              // Active account info
              _buildActiveAccountInfo(context, accountManager),
            ],
          ),
          actions: [
            // Call action
            _buildCallAction(context, accountManager),
            
            // Delete action (only if enabled)
            if (showDeleteAction && onDelete != null)
              _buildDeleteAction(context),
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
        );
      },
    );
  }

  /// Build active account info widget
  Widget _buildActiveAccountInfo(BuildContext context, MultiAccountManager accountManager) {
    final activeAccount = accountManager.activeAccount;
    final activeSipService = accountManager.activeSipService;

    if (activeAccount == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'No active account',
          style: TextStyle(
            color: Colors.orange,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    final connectionStatus = activeSipService?.status ?? SipConnectionStatus.disconnected;
    final statusColor = _getConnectionStatusColor(connectionStatus);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Calling from ${activeAccount.displayName}',
            style: TextStyle(
              fontSize: 12,
              color: AppThemes.getSecondaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  /// Build call action
  Widget _buildCallAction(BuildContext context, MultiAccountManager accountManager) {
    final canCall = _canMakeCall(accountManager);

    return CupertinoActionSheetAction(
      onPressed: () {
        Navigator.pop(context);
        if (canCall) {
          _makeCallWithActiveAccount(accountManager, phoneNumber);
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.phone,
            color: canCall ? Theme.of(context).colorScheme.primary : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            'Call',
            style: TextStyle(
              color: canCall ? Theme.of(context).colorScheme.primary : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// Build delete action
  Widget _buildDeleteAction(BuildContext context) {
    return CupertinoActionSheetAction(
      onPressed: () {
        Navigator.pop(context);
        if (onDelete != null) {
          onDelete!();
        }
      },
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.delete, color: Color(0xFFFF3B30)),
          SizedBox(width: 8),
          Text('Delete', style: TextStyle(color: Color(0xFFFF3B30))),
        ],
      ),
    );
  }

  /// Check if call can be made with active account
  bool _canMakeCall(MultiAccountManager accountManager) {
    final activeSipService = accountManager.activeSipService;
    return activeSipService?.status == SipConnectionStatus.connected;
  }

  /// Make call with active account
  void _makeCallWithActiveAccount(MultiAccountManager accountManager, String number) {
    final activeSipService = accountManager.activeSipService;
    if (activeSipService?.status == SipConnectionStatus.connected) {
      activeSipService!.makeCall(number);
    }
  }

  /// Get connection status color
  Color _getConnectionStatusColor(SipConnectionStatus status) {
    switch (status) {
      case SipConnectionStatus.connected:
        return Colors.green;
      case SipConnectionStatus.connecting:
        return Colors.orange;
      case SipConnectionStatus.error:
        return Colors.red;
      case SipConnectionStatus.disconnected:
        return Colors.grey;
    }
  }

  /// Format time helper
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour == 0 ? 12 : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Format duration helper
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

/// Static method to show the action sheet
class ContactActionSheetHelper {
  static void show({
    required BuildContext context,
    required String displayName,
    required String phoneNumber,
    bool showDeleteAction = false,
    VoidCallback? onDelete,
    DateTime? callTimestamp,
    Duration? callDuration,
  }) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => SharedContactActionSheet(
        displayName: displayName,
        phoneNumber: phoneNumber,
        showDeleteAction: showDeleteAction,
        onDelete: onDelete,
        callTimestamp: callTimestamp,
        callDuration: callDuration,
      ),
    );
  }
}