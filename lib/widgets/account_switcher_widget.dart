// lib/widgets/account_switcher_widget.dart - Redesigned as Icon Button

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/multi_account_manager.dart';
import '../services/sip_service.dart';
import '../themes/app_themes.dart';

class AccountSwitcherWidget extends StatelessWidget {
  const AccountSwitcherWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MultiAccountManager>(
      builder: (context, accountManager, child) {
        if (!accountManager.hasAccounts) {
          return const SizedBox.shrink();
        }

        final activeAccount = accountManager.activeAccount;
        if (activeAccount == null) {
          return const SizedBox.shrink();
        }

        return IconButton(
          onPressed: () => _showAccountSwitcher(context, accountManager),
          icon: Stack(
            children: [
              // Main account avatar
              _buildAccountAvatar(activeAccount),

              // Connection status indicator (small dot)
              Positioned(
                right: 0,
                bottom: 0,
                child: _buildConnectionStatusDot(accountManager, activeAccount),
              ),
            ],
          ),
          iconSize: 32, // Size of the avatar
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        );
      },
    );
  }

  /// Build account avatar (main icon)
  Widget _buildAccountAvatar(AccountInfo account) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: _getAvatarColor(account.id),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Center(
        child: Text(
          _getInitials(account.displayName),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Build small connection status dot
  Widget _buildConnectionStatusDot(
    MultiAccountManager accountManager,
    AccountInfo account,
  ) {
    final sipService = accountManager.getSipService(account.id);
    final connectionStatus =
        sipService?.status ?? SipConnectionStatus.disconnected;
    final statusColor = _getConnectionStatusColor(connectionStatus);

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: statusColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else {
      return name[0].toUpperCase();
    }
  }

  Color _getAvatarColor(String accountId) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    final index = accountId.hashCode % colors.length;
    return colors[index.abs()];
  }

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

  void _showAccountSwitcher(
    BuildContext context,
    MultiAccountManager accountManager,
  ) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (BuildContext context) =>
              _AccountSwitcherModal(accountManager: accountManager),
    );
  }
}

// Keep the same modal as before - no changes needed
class _AccountSwitcherModal extends StatelessWidget {
  final MultiAccountManager accountManager;

  const _AccountSwitcherModal({required this.accountManager});

  @override
  Widget build(BuildContext context) {
    return CupertinoActionSheet(
      title: Text(
        'Select Active Account',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      message: Text(
        'Choose which account to use for outgoing calls',
        style: TextStyle(
          fontSize: 14,
          color: AppThemes.getSecondaryTextColor(context),
        ),
      ),
      actions: [
        ...accountManager.accounts.values.map(
          (account) => _buildAccountAction(context, account),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(context),
        child: Text(
          'Cancel',
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }

  Widget _buildAccountAction(BuildContext context, AccountInfo account) {
  final isActive = accountManager.activeAccountId == account.id;
  final sipService = accountManager.getSipService(account.id);
  final connectionStatus =
      sipService?.status ?? SipConnectionStatus.disconnected;

  return CupertinoActionSheetAction(
    onPressed: () {
      Navigator.pop(context);
      if (!isActive) {
        accountManager.setActiveAccount(account.id);
      }
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getAvatarColor(account.id),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _getInitials(account.displayName),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // 2. Account Info (column), directly next to avatar
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    account.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isActive
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 4),
                  if (isActive)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                account.username,
                style: TextStyle(
                  fontSize: 14,
                  color: AppThemes.getSecondaryTextColor(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),

          // 3. Push connection status to end
          const Spacer(),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getConnectionStatusColor(connectionStatus),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _getConnectionStatusText(connectionStatus),
                style: TextStyle(
                  fontSize: 12,
                  color: AppThemes.getSecondaryTextColor(context),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else {
      return name[0].toUpperCase();
    }
  }

  Color _getAvatarColor(String accountId) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    final index = accountId.hashCode % colors.length;
    return colors[index.abs()];
  }

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

  String _getConnectionStatusText(SipConnectionStatus status) {
    switch (status) {
      case SipConnectionStatus.connected:
        return 'Connected';
      case SipConnectionStatus.connecting:
        return 'Connecting';
      case SipConnectionStatus.error:
        return 'Error';
      case SipConnectionStatus.disconnected:
        return 'Offline';
    }
  }
}
