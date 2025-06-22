// lib/screens/settings_tab.dart - Refactored & Clean

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/call_history_manager.dart';
import '../services/multi_account_manager.dart';
import '../services/sip_service.dart';
import '../services/theme_service.dart' as services;
import '../widgets/theme_selector.dart';
import '../themes/app_themes.dart';
import '../screens/about_page.dart';
import '../screens/qr_login_screen.dart';
import 'account_settings_page.dart'; // Import the separated page

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ADDED: Make setState method accessible to child widgets
  void refreshState() {
    if (mounted) {
      setState(() {
        // Force rebuild to show updated connection states
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

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
                        _AppHeader(scale: scale),
                        SizedBox(height: 32 * scale),
                        _AccountsSection(
                          accountManager: accountManager,
                          scale: scale,
                          parentState:
                              this, // ADDED: Pass parent state reference
                        ),
                        SizedBox(height: 32 * scale),
                        _AppSettingsSection(
                          themeService: themeService,
                          scale: scale,
                        ),
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

  double _calculateScale(BoxConstraints constraints) {
    const baseWidth = 375.0;
    const baseHeight = 667.0;
    final scaleWidth = constraints.maxWidth / baseWidth;
    final scaleHeight = constraints.maxHeight / baseHeight;
    return (scaleWidth + scaleHeight) / 2;
  }
}

// Header Section Widget
class _AppHeader extends StatelessWidget {
  final double scale;

  const _AppHeader({required this.scale});

  @override
  Widget build(BuildContext context) {
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
          _buildIcon(),
          SizedBox(height: 16 * scale),
          _buildTitle(context),
          SizedBox(height: 8 * scale),
          _buildDescription(context),
        ],
      ),
    );
  }

  Widget _buildIcon() {
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

  Widget _buildTitle(BuildContext context) {
    return Text(
      'Settings',
      style: TextStyle(
        fontSize: 28 * scale,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
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
}

// Accounts Section Widget
class _AccountsSection extends StatelessWidget {
  final MultiAccountManager accountManager;
  final double scale;
  final _SettingsTabState? parentState; // ADDED: Parent state reference

  const _AccountsSection({
    required this.accountManager,
    required this.scale,
    this.parentState, // ADDED: Optional parent state
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: 'Accounts',
      scale: scale,
      children: [
        ..._buildAccountItems(context),
        if (accountManager.hasAccounts) const _SettingsDivider(),
        _AddAccountItem(
          scale: scale,
          parentState: parentState,
        ), // ADDED: Pass parent state
      ],
    );
  }

  List<Widget> _buildAccountItems(BuildContext context) {
    final items = <Widget>[];
    final accounts = accountManager.accounts.values.toList();

    for (int i = 0; i < accounts.length; i++) {
      items.add(
        _AccountItem(
          accountManager: accountManager,
          account: accounts[i],
          scale: scale,
          parentState: parentState, // ADDED: Pass parent state
        ),
      );

      if (i < accounts.length - 1) {
        items.add(const _SettingsDivider());
      }
    }

    return items;
  }
}

// Individual Account Item Widget
class _AccountItem extends StatelessWidget {
  final MultiAccountManager accountManager;
  final AccountInfo account;
  final double scale;
  final _SettingsTabState? parentState; // ADDED: Parent state reference

  const _AccountItem({
    required this.accountManager,
    required this.account,
    required this.scale,
    this.parentState, // ADDED: Optional parent state
  });

  @override
  Widget build(BuildContext context) {
    // FIXED: Use Consumer to listen to real-time state changes
    return Consumer<MultiAccountManager>(
      builder: (context, accountManager, child) {
        final isActive = accountManager.activeAccountId == account.id;
        final sipService = accountManager.getSipService(account.id);
        final connectionStatus =
            sipService?.status ?? SipConnectionStatus.disconnected;

        return _SettingsItem(
          icon: CupertinoIcons.person_circle,
          iconColor: _getAvatarColor(account.id),
          title: account.displayName,
          subtitle:
              '${account.username} • ${_getConnectionStatusText(connectionStatus)}',
          trailing: _AccountTrailing(
            isActive: isActive,
            connectionStatus: connectionStatus,
            scale: scale,
          ),
          onTap: () => _navigateToAccountSettings(context, account),
          scale: scale,
        );
      },
    );
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

  Future<void> _navigateToAccountSettings(
    BuildContext context,
    AccountInfo account,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountSettingsPage(account: account),
      ),
    );

    // ADDED: Force refresh after returning from account settings
    parentState?.refreshState();
  }
}

// Account Trailing Widget
class _AccountTrailing extends StatelessWidget {
  final bool isActive;
  final SipConnectionStatus connectionStatus;
  final double scale;

  const _AccountTrailing({
    required this.isActive,
    required this.connectionStatus,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isActive) ...[_buildActiveBadge(), SizedBox(width: 8 * scale)],
        _buildStatusDot(),
        SizedBox(width: 8 * scale),
        _buildChevron(context),
      ],
    );
  }

  Widget _buildActiveBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 4 * scale),
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
    );
  }

  Widget _buildStatusDot() {
    return Container(
      width: 8 * scale,
      height: 8 * scale,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getConnectionStatusColor(connectionStatus),
      ),
    );
  }

  Widget _buildChevron(BuildContext context) {
    return Icon(
      Icons.chevron_right,
      color: AppThemes.getSecondaryTextColor(context),
      size: 16 * scale,
    );
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
}

// Add Account Item Widget
class _AddAccountItem extends StatelessWidget {
  final double scale;
  final _SettingsTabState? parentState; // ADDED: Parent state reference

  const _AddAccountItem({
    required this.scale,
    this.parentState, // ADDED: Optional parent state
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsItem(
      icon: CupertinoIcons.add_circled,
      iconColor: Colors.green,
      title: 'Add Account',
      subtitle: 'Login with QR code or manual setup',
      trailing: _buildChevron(context),
      onTap: () => _navigateToAddAccount(context),
      scale: scale,
    );
  }

  Widget _buildChevron(BuildContext context) {
    return Icon(
      Icons.chevron_right,
      color: AppThemes.getSecondaryTextColor(context),
      size: 16 * scale,
    );
  }

  Future<void> _navigateToAddAccount(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRLoginScreen()),
    );

    // ADDED: Force refresh after adding new account
    parentState?.refreshState();
  }
}

// App Settings Section Widget
class _AppSettingsSection extends StatelessWidget {
  final services.ThemeService themeService;
  final double scale;

  const _AppSettingsSection({required this.themeService, required this.scale});

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: 'App Settings',
      scale: scale,
      children: [
        _ThemeSettingsItem(themeService: themeService, scale: scale),
        const _SettingsDivider(),
        _ClearHistorySettingsItem(scale: scale),
        const _SettingsDivider(),
        _AboutSettingsItem(scale: scale),
      ],
    );
  }
}

// Theme Settings Item Widget
class _ThemeSettingsItem extends StatelessWidget {
  final services.ThemeService themeService;
  final double scale;

  const _ThemeSettingsItem({required this.themeService, required this.scale});

  @override
  Widget build(BuildContext context) {
    return _SettingsItem(
      icon: CupertinoIcons.paintbrush,
      iconColor: Colors.purple,
      title: 'Appearance',
      subtitle: _getThemeDisplayText(themeService.themeMode),
      trailing: _buildChevron(context),
      onTap: () => _navigateToThemeSelector(context),
      scale: scale,
    );
  }

  Widget _buildChevron(BuildContext context) {
    return Icon(
      Icons.chevron_right,
      color: AppThemes.getSecondaryTextColor(context),
      size: 16 * scale,
    );
  }

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

  void _navigateToThemeSelector(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ThemeSelector()),
    );
  }
}

// Clear History Settings Item Widget
class _ClearHistorySettingsItem extends StatelessWidget {
  final double scale;

  const _ClearHistorySettingsItem({required this.scale});

  @override
  Widget build(BuildContext context) {
    return _SettingsItem(
      icon: CupertinoIcons.trash,
      iconColor: Colors.red,
      title: 'Clear History',
      subtitle: 'Delete all call history',
      trailing: _buildChevron(context),
      onTap: () => _showClearHistoryDialog(context),
      scale: scale,
    );
  }

  Widget _buildChevron(BuildContext context) {
    return Icon(
      Icons.chevron_right,
      color: AppThemes.getSecondaryTextColor(context),
      size: 16 * scale,
    );
  }

  void _showClearHistoryDialog(BuildContext context) {
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
              onPressed: () => _clearHistory(context),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearHistory(BuildContext context) async {
    Navigator.of(context).pop();

    try {
      await CallHistoryManager.clearHistory();
      if (context.mounted) {
        _showSuccessDialog(context, 'Call history cleared successfully.');
      }
    } catch (error) {
      if (context.mounted) {
        _showErrorDialog(context, 'Failed to clear call history.');
      }
    }
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Success'),
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

  void _showErrorDialog(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
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

// About Settings Item Widget
class _AboutSettingsItem extends StatelessWidget {
  final double scale;

  const _AboutSettingsItem({required this.scale});

  @override
  Widget build(BuildContext context) {
    return _SettingsItem(
      icon: CupertinoIcons.info_circle,
      iconColor: Colors.green,
      title: 'About',
      subtitle: 'App information and credits',
      trailing: _buildChevron(context),
      onTap: () => _navigateToAboutPage(context),
      scale: scale,
    );
  }

  Widget _buildChevron(BuildContext context) {
    return Icon(
      Icons.chevron_right,
      color: AppThemes.getSecondaryTextColor(context),
      size: 16 * scale,
    );
  }

  void _navigateToAboutPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AboutPage()),
    );
  }
}

// Reusable Components

// Generic Settings Section Container
class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final double scale;

  const _SettingsSection({
    required this.title,
    required this.children,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_buildHeader(context), _buildContainer(context)],
    );
  }

  Widget _buildHeader(BuildContext context) {
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

  Widget _buildContainer(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16 * scale),
      decoration: BoxDecoration(
        color: AppThemes.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(12 * scale),
      ),
      child: Column(children: children),
    );
  }
}

// Generic Settings Item
class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;
  final double scale;

  const _SettingsItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12 * scale),
        child: Padding(
          padding: EdgeInsets.all(16 * scale),
          child: Row(
            children: [
              _buildIcon(),
              SizedBox(width: 12 * scale),
              _buildContent(context),
              SizedBox(width: 8 * scale),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: EdgeInsets.all(8 * scale),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8 * scale),
      ),
      child: Icon(icon, color: iconColor, size: 20 * scale),
    );
  }

  Widget _buildContent(BuildContext context) {
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
}

// Settings Divider
class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.only(left: 56),
      color: AppThemes.getDividerColor(context),
    );
  }
}
