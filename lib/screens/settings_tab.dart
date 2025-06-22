// lib/screens/settings_tab.dart - Updated with Multi-Account Support

import 'package:dash_call/services/call_history_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/multi_account_manager.dart';
import '../services/sip_service.dart';
import '../services/theme_service.dart' as services;
import '../widgets/theme_selector.dart';
import '../themes/app_themes.dart';
import '../screens/about_page.dart';
import '../screens/debug_connection_page.dart';
import '../screens/qr_login_screen.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<MultiAccountManager, services.ThemeService>(
      builder: (context, accountManager, themeService, child) {
        return Container(
          color: AppThemes.getSettingsBackgroundColor(context),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scale = _calculateScale(constraints);

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderContainer(scale),
                        SizedBox(height: 32 * scale),
                        _buildAccountsSection(accountManager, scale),
                        SizedBox(height: 32 * scale),
                        _buildAppSettingsSection(themeService, scale),
                        SizedBox(height: 50 * scale),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Calculate responsive scale based on screen constraints
  double _calculateScale(BoxConstraints constraints) {
    const baseWidth = 375.0;
    const baseHeight = 667.0;
    final scaleWidth = constraints.maxWidth / baseWidth;
    final scaleHeight = constraints.maxHeight / baseHeight;
    return (scaleWidth + scaleHeight) / 2;
  }

  /// Header container with app icon and description
  Widget _buildHeaderContainer(double scale) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(16 * scale),
      padding: EdgeInsets.all(32 * scale),
      decoration: BoxDecoration(
        color: AppThemes.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(20 * scale),
      ),
      child: Column(
        children: [
          _buildAppIcon(scale),
          SizedBox(height: 16 * scale),
          _buildHeaderText(scale),
          SizedBox(height: 8 * scale),
          _buildDescriptionText(scale),
        ],
      ),
    );
  }

  /// App icon container
  Widget _buildAppIcon(double scale) {
    return Container(
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        borderRadius: BorderRadius.circular(16 * scale),
      ),
      child: Icon(
        CupertinoIcons.settings_solid,
        size: 40 * scale,
        color: Colors.white,
      ),
    );
  }

  /// Header title text
  Widget _buildHeaderText(double scale) {
    return Text(
      'Settings',
      style: TextStyle(
        fontSize: 28 * scale,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  /// Description text
  Widget _buildDescriptionText(double scale) {
    return Text(
      'Manage your accounts, configure settings, and customize your calling experience.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14 * scale,
        color: AppThemes.getSecondaryTextColor(context),
        height: 1.4,
      ),
    );
  }

  /// Accounts Section - NEW: Shows all accounts + Add Account button
  Widget _buildAccountsSection(
    MultiAccountManager accountManager,
    double scale,
  ) {
    return _buildSettingsSection(
      title: 'Accounts',
      scale: scale,
      children: [
        // Show all accounts
        ...accountManager.accounts.values
            .map((account) => _buildAccountItem(accountManager, account, scale))
            .toList(),

        // Add divider if accounts exist
        if (accountManager.hasAccounts) _buildDivider(context),

        // Add Account button
        _buildAddAccountItem(scale),
      ],
    );
  }

  /// Individual Account Item - NEW
  Widget _buildAccountItem(
    MultiAccountManager accountManager,
    AccountInfo account,
    double scale,
  ) {
    final isActive = accountManager.activeAccountId == account.id;
    final sipService = accountManager.getSipService(account.id);
    final connectionStatus =
        sipService?.status ?? SipConnectionStatus.disconnected;

    return _buildSettingsItem(
      icon: CupertinoIcons.person_circle,
      iconColor: _getAvatarColor(account.id),
      title: account.displayName,
      subtitle:
          '${account.username} • ${_getConnectionStatusText(connectionStatus)}',
      trailing: _buildAccountTrailing(isActive, connectionStatus, scale),
      onTap: () => _navigateToAccountSettings(account),
      scale: scale,
    );
  }

  /// Add Account Item - NEW
  Widget _buildAddAccountItem(double scale) {
    return _buildSettingsItem(
      icon: CupertinoIcons.add_circled,
      iconColor: Colors.green,
      title: 'Add Account',
      subtitle: 'Login with QR code or manual setup',
      trailing: _buildChevronIcon(scale),
      onTap: _navigateToAddAccount,
      scale: scale,
    );
  }

  /// Account Trailing Widget - Shows active badge and connection status
  Widget _buildAccountTrailing(
    bool isActive,
    SipConnectionStatus connectionStatus,
    double scale,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Active badge
        if (isActive) ...[
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 8 * scale,
              vertical: 4 * scale,
            ),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12 * scale),
            ),
            child: Text(
              'Active',
              style: TextStyle(
                fontSize: 10 * scale,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ),
          SizedBox(width: 8 * scale),
        ],

        // Connection status dot
        Container(
          width: 8 * scale,
          height: 8 * scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getConnectionStatusColor(connectionStatus),
          ),
        ),

        SizedBox(width: 8 * scale),

        // Chevron
        Icon(
          Icons.chevron_right,
          color: AppThemes.getSecondaryTextColor(context),
          size: 16 * scale,
        ),
      ],
    );
  }

  /// App Settings Section
  Widget _buildAppSettingsSection(
    services.ThemeService themeService,
    double scale,
  ) {
    return _buildSettingsSection(
      title: 'App Settings',
      scale: scale,
      children: [
        _buildThemeSettingsItem(themeService, scale),
        _buildDivider(context),
        _buildClearHistorySettingsItem(scale),
        _buildDivider(context),
        _buildAboutSettingsItem(scale),
      ],
    );
  }

  /// Theme settings item
  Widget _buildThemeSettingsItem(
    services.ThemeService themeService,
    double scale,
  ) {
    return _buildSettingsItem(
      icon: CupertinoIcons.paintbrush,
      iconColor: Colors.purple,
      title: 'Appearance',
      subtitle: _getThemeDisplayText(themeService.themeMode),
      trailing: _buildChevronIcon(scale),
      onTap: () => _navigateToThemeSelector(),
      scale: scale,
    );
  }

  /// Clear History settings item
  Widget _buildClearHistorySettingsItem(double scale) {
    return _buildSettingsItem(
      icon: CupertinoIcons.trash,
      iconColor: Colors.red,
      title: 'Clear History',
      subtitle: 'Delete all call history',
      trailing: _buildChevronIcon(scale),
      onTap: () => _showClearHistoryDialog(),
      scale: scale,
    );
  }

  /// About settings item
  Widget _buildAboutSettingsItem(double scale) {
    return _buildSettingsItem(
      icon: CupertinoIcons.info_circle,
      iconColor: Colors.green,
      title: 'About',
      subtitle: 'App information and credits',
      trailing: _buildChevronIcon(scale),
      onTap: () => _navigateToAboutPage(),
      scale: scale,
    );
  }

  /// Generic settings section builder
  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
    required double scale,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title, scale),
        _buildSectionContainer(children, scale),
      ],
    );
  }

  /// Section header with title
  Widget _buildSectionHeader(String title, double scale) {
    return Padding(
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
    );
  }

  /// Section container with rounded corners
  Widget _buildSectionContainer(List<Widget> children, double scale) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16 * scale),
      decoration: BoxDecoration(
        color: AppThemes.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(12 * scale),
      ),
      child: Column(children: children),
    );
  }

  /// Generic settings item builder
  Widget _buildSettingsItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
    required double scale,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12 * scale),
        child: Padding(
          padding: EdgeInsets.all(16 * scale),
          child: Row(
            children: [
              _buildItemIcon(icon, iconColor, scale),
              SizedBox(width: 12 * scale),
              _buildItemContent(title, subtitle, scale),
              SizedBox(width: 8 * scale),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  /// Settings item icon
  Widget _buildItemIcon(IconData icon, Color iconColor, double scale) {
    return Container(
      padding: EdgeInsets.all(8 * scale),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8 * scale),
      ),
      child: Icon(icon, color: iconColor, size: 20 * scale),
    );
  }

  /// Settings item content (title and subtitle)
  Widget _buildItemContent(String title, String subtitle, double scale) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16 * scale,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2 * scale),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13 * scale,
              color: AppThemes.getSecondaryTextColor(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Chevron icon for navigation
  Widget _buildChevronIcon(double scale) {
    return Icon(
      Icons.chevron_right,
      color: AppThemes.getSecondaryTextColor(context),
      size: 16 * scale,
    );
  }

  /// Divider builder
  Widget _buildDivider(BuildContext context) {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.only(left: 56),
      color: AppThemes.getDividerColor(context),
    );
  }

  /// Get theme display text
  String _getThemeDisplayText(services.ThemeMode themeMode) {
    switch (themeMode) {
      case services.ThemeMode.system:
        return 'System';
      case services.ThemeMode.light:
        return 'Light';
      case services.ThemeMode.dark:
        return 'Dark';
    }
  }

  /// Get avatar color for account
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

  /// Get connection status text
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

  /// Navigate to theme selector
  void _navigateToThemeSelector() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ThemeSelector()),
    );
  }

  /// Navigate to about page
  void _navigateToAboutPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AboutPage()),
    );
  }

  /// Navigate to add account (QR Login)
  void _navigateToAddAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRLoginScreen()),
    );
  }

  /// Navigate to individual account settings
  void _navigateToAccountSettings(AccountInfo account) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountSettingsPage(account: account),
      ),
    );
  }

  /// Show clear history dialog with CupertinoAlertDialog
  void _showClearHistoryDialog() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Clear Call History'),
          content: const Text(
            'Are you sure you want to delete all call history? This action cannot be undone.',
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Clear'),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await CallHistoryManager.clearHistory();
                  if (mounted) {
                    showCupertinoDialog(
                      context: context,
                      builder:
                          (context) => CupertinoAlertDialog(
                            title: const Text('Success'),
                            content: const Text(
                              'Call history cleared successfully.',
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
                } catch (error) {
                  if (mounted) {
                    showCupertinoDialog(
                      context: context,
                      builder:
                          (context) => CupertinoAlertDialog(
                            title: const Text('Error'),
                            content: const Text(
                              'Failed to clear call history.',
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
                }
              },
            ),
          ],
        );
      },
    );
  }
}

// Individual Account Settings Page - NEW
class AccountSettingsPage extends StatefulWidget {
  final AccountInfo account;

  const AccountSettingsPage({super.key, required this.account});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  @override
  Widget build(BuildContext context) {
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

  /// Build app bar
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

  /// Build main body
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
                  _buildServerConnectionSection(
                    accountManager,
                    sipService,
                    scale,
                  ),
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

  /// Calculate responsive scale
  double _calculateScale(BoxConstraints constraints) {
    const baseWidth = 375.0;
    const baseHeight = 667.0;
    final scaleWidth = constraints.maxWidth / baseWidth;
    final scaleHeight = constraints.maxHeight / baseHeight;
    return (scaleWidth + scaleHeight) / 2;
  }

  /// Account Information Section
  Widget _buildAccountInformationSection(double scale) {
    return _buildNativeSection(
      title: 'Account Information',
      children: [
        _buildInfoRow(
          'Account Name',
          widget.account.accountName.isNotEmpty
              ? widget.account.accountName
              : 'Not configured',
          scale: scale,
        ),
        _buildInfoRow(
          'Organization',
          widget.account.organization.isNotEmpty
              ? widget.account.organization
              : 'Not configured',
          scale: scale,
        ),
        _buildInfoRow('Extension', widget.account.username, scale: scale),
        _buildInfoRow(
          'Server',
          '${widget.account.sipServer}:${widget.account.port}',
          scale: scale,
        ),
      ],
      scale: scale,
    );
  }

  /// Server Connection Section
  Widget _buildServerConnectionSection(
    MultiAccountManager accountManager,
    SipService? sipService,
    double scale,
  ) {
    return _buildNativeSection(
      title: 'Server Connection',
      children: [
        _buildServerConnectionToggle(accountManager, sipService, scale),
      ],
      scale: scale,
    );
  }

  /// Server Connection Toggle Item
  Widget _buildServerConnectionToggle(
    MultiAccountManager accountManager,
    SipService? sipService,
    double scale,
  ) {
    final connectionStatus =
        sipService?.status ?? SipConnectionStatus.disconnected;
    final isConnected = connectionStatus == SipConnectionStatus.connected;
    final isConnecting = connectionStatus == SipConnectionStatus.connecting;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16 * scale,
        vertical: 12 * scale,
      ),
      child: Row(
        children: [
          // Connection Icon
          Container(
            padding: EdgeInsets.all(8 * scale),
            decoration: BoxDecoration(
              color: _getConnectionToggleIconColor(
                connectionStatus,
              ).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8 * scale),
            ),
            child: Icon(
              _getConnectionToggleIcon(connectionStatus),
              color: _getConnectionToggleIconColor(connectionStatus),
              size: 20 * scale,
            ),
          ),

          SizedBox(width: 12 * scale),

          // Connection Text
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

          // Toggle Switch
          CupertinoSwitch(
            value: isConnected || isConnecting,
            onChanged:
                isConnecting
                    ? null
                    : (value) => _handleConnectionToggle(value, sipService),
            activeColor: Colors.green,
            trackColor: Colors.grey.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  /// Debug Commands Section
  Widget _buildDebugCommandsSection(double scale) {
    return _buildNativeSection(
      title: 'Debug Commands',
      children: [_buildDebugCommandsItem(scale)],
      scale: scale,
    );
  }

  /// Debug commands item
  Widget _buildDebugCommandsItem(double scale) {
    return Container(
      decoration: BoxDecoration(
        color: AppThemes.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(10 * scale),
      ),
      child: Material(
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
      ),
    );
  }

  /// Danger Zone Section
  Widget _buildDangerZoneSection(
    MultiAccountManager accountManager,
    double scale,
  ) {
    return _buildNativeSection(
      title: 'Danger Zone',
      children: [_buildDeleteAccountItem(accountManager, scale)],
      scale: scale,
    );
  }

  /// Delete account item
  Widget _buildDeleteAccountItem(
    MultiAccountManager accountManager,
    double scale,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppThemes.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(10 * scale),
      ),
      child: Material(
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
      ),
    );
  }

  /// Generic native section builder
  Widget _buildNativeSection({
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

  /// Info row builder
  Widget _buildInfoRow(String label, String value, {required double scale}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16 * scale,
        vertical: 12 * scale,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppThemes.getDividerColor(context).withOpacity(0.3),
            width: 0.5,
          ),
        ),
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

  /// Get connection toggle icon based on status
  IconData _getConnectionToggleIcon(SipConnectionStatus status) {
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

  /// Get connection toggle icon color based on status
  Color _getConnectionToggleIconColor(SipConnectionStatus status) {
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

  /// Get connection status text
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

  /// Handle connection toggle
  Future<void> _handleConnectionToggle(
    bool value,
    SipService? sipService,
  ) async {
    if (sipService == null) return;

    try {
      if (value) {
        print(
          '🔌 [AccountSettings] Connecting account: ${widget.account.displayName}',
        );
        await sipService.register();
      } else {
        print(
          '🔌 [AccountSettings] Disconnecting account: ${widget.account.displayName}',
        );
        await sipService.unregister();
      }
    } catch (e) {
      print('❌ [AccountSettings] Connection toggle error: $e');
    }
  }

  /// Navigate to debug page
  void _navigateToDebugPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DebugConnectionPage()),
    );
  }

  /// Show delete account dialog with CupertinoAlertDialog
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
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog

                try {
                  final success = await accountManager.removeAccount(
                    widget.account.id,
                  );

                  if (success && mounted) {
                    // Go back to settings if account deleted successfully
                    Navigator.of(context).pop();

                    // Show success message
                    showCupertinoDialog(
                      context: context,
                      builder:
                          (context) => CupertinoAlertDialog(
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
                  } else if (mounted) {
                    // Show error message
                    showCupertinoDialog(
                      context: context,
                      builder:
                          (context) => CupertinoAlertDialog(
                            title: const Text('Error'),
                            content: const Text(
                              'Failed to delete the account. Please try again.',
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
                } catch (error) {
                  if (mounted) {
                    showCupertinoDialog(
                      context: context,
                      builder:
                          (context) => CupertinoAlertDialog(
                            title: const Text('Error'),
                            content: const Text(
                              'An error occurred while deleting the account.',
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
                }
              },
            ),
          ],
        );
      },
    );
  }
}
