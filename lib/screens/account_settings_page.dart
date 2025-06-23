// lib/screens/account_settings_page.dart - FIXED: Proper navigation when deleting last account

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/multi_account_manager.dart';
import '../services/sip_service.dart';
import '../themes/app_themes.dart';
import 'debug_connection_page.dart';

class AccountSettingsPage extends StatefulWidget {
  final AccountInfo account;

  const AccountSettingsPage({super.key, required this.account});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Timer? _statusUpdateTimer;

  @override
  void initState() {
    super.initState();
    _startStatusUpdates();
  }

  @override
  void dispose() {
    _statusUpdateTimer?.cancel();
    super.dispose();
  }

  void _startStatusUpdates() {
    _statusUpdateTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) {
      if (mounted) {
        setState(() {
          // Trigger rebuild every 500ms for real-time status updates
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<MultiAccountManager>(
      builder: (context, accountManager, child) {
        final sipService = accountManager.getSipService(widget.account.id);

        return Scaffold(
          backgroundColor: AppThemes.getSettingsBackgroundColor(context),
          appBar: _buildAppBar(),
          body: _buildBody(accountManager, sipService),
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
        widget.account.displayName,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onBackground,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody(
    MultiAccountManager accountManager,
    SipService? sipService,
  ) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = _calculateScale(constraints);
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                children: [
                  SizedBox(height: 20 * scale),
                  _buildAccountInformationSection(scale),
                  SizedBox(height: 32 * scale),
                  _buildAccountStatusSection(accountManager, sipService, scale),
                  SizedBox(height: 32 * scale),
                  _buildDebugCommandsSection(scale),
                  SizedBox(height: 35 * scale),
                  _buildDangerZoneSection(accountManager, scale),
                  SizedBox(height: 50 * scale),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  double _calculateScale(BoxConstraints constraints) {
    const baseWidth = 375.0;
    const baseHeight = 667.0;
    final scaleWidth = constraints.maxWidth / baseWidth;
    final scaleHeight = constraints.maxHeight / baseHeight;
    return (scaleWidth + scaleHeight) / 2;
  }

  Widget _buildAccountStatusSection(
    MultiAccountManager accountManager,
    SipService? sipService,
    double scale,
  ) {
    final connectionStatus =
        sipService?.status ?? SipConnectionStatus.disconnected;

    return _buildSection(
      title: 'Account Status',
      children: [
        _buildStatusRow(
          'Connection Status',
          _getConnectionStatusText(connectionStatus),
          statusColor: _getConnectionStatusColor(connectionStatus),
          scale: scale,
        ),
        _buildDivider(),
        _buildConnectionToggleItem(accountManager, sipService, scale),
      ],
      scale: scale,
    );
  }

  Widget _buildAccountInformationSection(double scale) {
    return _buildSection(
      title: 'Account Information',
      children: [
        _buildInfoRow(
          'Display Name',
          widget.account.displayName.isNotEmpty
              ? widget.account.displayName
              : 'Not configured',
          scale: scale,
        ),
        _buildDivider(),
        _buildInfoRow(
          'Organization',
          widget.account.organization.isNotEmpty
              ? widget.account.organization
              : 'Not configured',
          scale: scale,
        ),
        _buildDivider(),
        _buildInfoRow('Extension', widget.account.username, scale: scale),
      ],
      scale: scale,
    );
  }

  Widget _buildDebugCommandsSection(double scale) {
    return _buildSection(
      title: 'Debug Commands',
      children: [_buildDebugCommandsItem(scale)],
      scale: scale,
    );
  }

  Widget _buildDangerZoneSection(
    MultiAccountManager accountManager,
    double scale,
  ) {
    return _buildSection(
      title: 'Danger Zone',
      children: [_buildDeleteAccountItem(accountManager, scale)],
      scale: scale,
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    required double scale,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16 * scale,
            vertical: 8 * scale,
          ),
          child: Text(
            title,
            style: TextStyle(
              color: AppThemes.getSecondaryTextColor(context),
              fontSize: 13 * scale,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16 * scale),
          decoration: BoxDecoration(
            color: AppThemes.getCardBackgroundColor(context),
            borderRadius: BorderRadius.circular(10 * scale),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildConnectionToggleItem(
    MultiAccountManager accountManager,
    SipService? sipService,
    double scale,
  ) {
    final connectionStatus =
        sipService?.status ?? SipConnectionStatus.disconnected;
    final isConnected = connectionStatus == SipConnectionStatus.connected;
    final isConnecting = connectionStatus == SipConnectionStatus.connecting;
    final canToggle = sipService != null && !isConnecting;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16 * scale,
        vertical: 12 * scale,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8 * scale),
            decoration: BoxDecoration(
              color: _getConnectionIconColor(connectionStatus).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8 * scale),
            ),
            child: Icon(
              _getConnectionIcon(connectionStatus),
              color: _getConnectionIconColor(connectionStatus),
              size: 20 * scale,
            ),
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Server Connection',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  _getConnectionStatusText(connectionStatus),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppThemes.getSecondaryTextColor(context),
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: isConnected || isConnecting,
            onChanged:
                canToggle
                    ? (value) => _handleConnectionToggle(value, sipService!)
                    : null,
            activeColor: Colors.green,
            trackColor: Colors.grey.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(
    String label,
    String value, {
    required Color statusColor,
    required double scale,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16 * scale,
        vertical: 12 * scale,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 17 * scale,
              fontWeight: FontWeight.w400,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 8 * scale),
              Text(
                value,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 17 * scale,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.end,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {required double scale}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16 * scale,
        vertical: 12 * scale,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 17 * scale,
              fontWeight: FontWeight.w400,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: AppThemes.getSecondaryTextColor(context),
                fontSize: 17 * scale,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugCommandsItem(double scale) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10 * scale),
        onTap: _navigateToDebugPage,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16 * scale,
            vertical: 12 * scale,
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(6 * scale),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6 * scale),
                ),
                child: Icon(
                  Icons.terminal,
                  color: Colors.orange,
                  size: 18 * scale,
                ),
              ),
              SizedBox(width: 12 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debug Connection',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'View live SIP and WebSocket logs',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppThemes.getSecondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.right_chevron,
                color: AppThemes.getSecondaryTextColor(context),
                size: 20 * scale,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteAccountItem(
    MultiAccountManager accountManager,
    double scale,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10 * scale),
        onTap: () => _showDeleteAccountDialog(accountManager),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16 * scale,
            vertical: 12 * scale,
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(6 * scale),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6 * scale),
                ),
                child: Icon(
                  CupertinoIcons.delete,
                  color: Colors.red,
                  size: 18 * scale,
                ),
              ),
              SizedBox(width: 12 * scale),
              const Expanded(
                child: Text(
                  'Delete Account',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Icon(
                CupertinoIcons.right_chevron,
                color: AppThemes.getSecondaryTextColor(context),
                size: 20 * scale,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.only(left: 16),
      color: AppThemes.getDividerColor(context).withOpacity(0.3),
    );
  }

  // Connection status helpers
  IconData _getConnectionIcon(SipConnectionStatus status) {
    switch (status) {
      case SipConnectionStatus.connected:
        return Icons.wifi;
      case SipConnectionStatus.connecting:
        return Icons.wifi_find;
      case SipConnectionStatus.error:
        return Icons.wifi_off;
      case SipConnectionStatus.disconnected:
        return Icons.wifi_off;
    }
  }

  Color _getConnectionIconColor(SipConnectionStatus status) {
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
        return 'Connecting...';
      case SipConnectionStatus.error:
        return 'Connection Error';
      case SipConnectionStatus.disconnected:
        return 'Disconnected';
    }
  }

  // Actions
  Future<void> _handleConnectionToggle(
    bool value,
    SipService sipService,
  ) async {
    try {
      setState(() {});

      if (value) {
        await sipService.register();
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          setState(() {});
        }
      } else {
        await sipService.unregister();
        await Future.delayed(const Duration(milliseconds: 300));

        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _navigateToDebugPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DebugConnectionPage()),
    );
  }

  void _showDeleteAccountDialog(MultiAccountManager accountManager) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Delete Account'),
          content: Text(
            'Are you sure you want to delete "${widget.account.displayName}"? This will remove all saved settings and disconnect from the SIP server.',
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Delete'),
              onPressed: () => _deleteAccount(accountManager),
            ),
          ],
        );
      },
    );
  }

  // FIXED: Proper navigation when deleting last account
  Future<void> _deleteAccount(MultiAccountManager accountManager) async {
    Navigator.of(context).pop(); // Close dialog

    try {
      // Check if this is the last account before deletion
      final isLastAccount = accountManager.accountCount == 1;
      
      print('🗑️ [AccountSettings] Deleting account: ${widget.account.displayName}');
      print('📊 [AccountSettings] Is last account: $isLastAccount');
      
      final success = await accountManager.removeAccount(widget.account.id);

      if (success && mounted) {
        if (isLastAccount) {
          // FIXED: Navigate to login screen when deleting the last account
          print('🔄 [AccountSettings] Last account deleted, navigating to login...');
          
          // Navigate to login and clear all previous routes
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/qr-login',
            (route) => false, // Remove all previous routes
          );
          
          // Show confirmation that the account was deleted
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              showCupertinoDialog(
                context: context,
                builder: (context) => CupertinoAlertDialog(
                  title: const Text('Account Deleted'),
                  content: Text(
                    '${widget.account.displayName} was successfully removed. Please add a new account to continue.',
                  ),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text('OK'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              );
            }
          });
        } else {
          // FIXED: Navigate back to settings when there are still other accounts
          print('🔄 [AccountSettings] Account deleted, returning to settings...');
          Navigator.of(context).pop(); // Go back to settings

          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Account Deleted'),
              content: Text(
                '${widget.account.displayName} was successfully removed.',
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        }
      } else if (mounted) {
        _showErrorDialog('Failed to delete the account. Please try again.');
      }
    } catch (error) {
      print('❌ [AccountSettings] Error deleting account: $error');
      if (mounted) {
        _showErrorDialog('An error occurred while deleting the account.');
      }
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}