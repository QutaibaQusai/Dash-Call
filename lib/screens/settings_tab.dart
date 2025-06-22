// lib/screens/settings_tab.dart - Updated with Server Connection Toggle

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:dash_call/services/call_history_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sip_service.dart';
import '../services/theme_service.dart' as services;
import '../widgets/theme_selector.dart';
import '../themes/app_themes.dart';
import '../screens/about_page.dart';
import '../screens/debug_connection_page.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<SipService, services.ThemeService>(
      builder: (context, sipService, themeService, child) {
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
                        _buildAccountSettingsSection(sipService, scale),
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
      'Configure your SIP connection settings, manage your account preferences, and customize your calling experience.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14 * scale,
        color: AppThemes.getSecondaryTextColor(context),
        height: 1.4,
      ),
    );
  }

  /// Account Settings Section
  Widget _buildAccountSettingsSection(SipService sipService, double scale) {
    return _buildSettingsSection(
      title: 'Accounts',
      scale: scale,
      children: [_buildAccountSettingsItem(sipService, scale)],
    );
  }

  /// Account settings item - UPDATED: Use account name as title, extension as subtitle, with connection status
  Widget _buildAccountSettingsItem(SipService sipService, double scale) {
    return _buildSettingsItem(
      icon: CupertinoIcons.info,
      iconColor: Colors.blue,
      title: _getAccountTitle(sipService), // Use account name or fallback
      subtitle: _getAccountSubtitle(sipService), // Show extension number
      trailing: _buildAccountTrailing(
        sipService,
        scale,
      ), // UPDATED: Custom trailing with status and chevron
      onTap: () => _navigateToConfigurationPage(sipService),
      scale: scale,
    );
  }

  /// UPDATED: Build account trailing with connection status and chevron
  Widget _buildAccountTrailing(SipService sipService, double scale) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8 * scale,
          height: 8 * scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getConnectionStatusColor(sipService.status),
          ),
        ),
        SizedBox(width: 8 * scale),
        // Chevron icon
        Icon(
          Icons.chevron_right,
          color: AppThemes.getSecondaryTextColor(context),
          size: 16 * scale,
        ),
      ],
    );
  }

  /// Get connection status color (same as main screen)
  Color _getConnectionStatusColor(SipConnectionStatus status) {
    switch (status) {
      case SipConnectionStatus.connected:
        return Colors.green;
      case SipConnectionStatus.connecting:
        return Colors.orange;
      case SipConnectionStatus.error:
        return Colors.red;
      case SipConnectionStatus.disconnected:
        return Colors.grey.shade400;
    }
  }

  /// Get account title (account name or fallback)
  String _getAccountTitle(SipService sipService) {
    if (sipService.accountName.isNotEmpty) {
      return sipService.accountName;
    }
    if (sipService.username.isNotEmpty) {
      return sipService.username;
    }
    return 'Account';
  }

  /// Get account subtitle (extension number)
  String _getAccountSubtitle(SipService sipService) {
    if (sipService.username.isNotEmpty) {
      return sipService.username;
    }
    return 'Not configured';
  }

  /// App Settings Section - UPDATED: Now includes both Theme and About items
  Widget _buildAppSettingsSection(
    services.ThemeService themeService,
    double scale,
  ) {
    return _buildSettingsSection(
      title: 'App Settings',
      scale: scale,
      children: [
        _buildThemeSettingsItem(themeService, scale),
        _buildClearHistorySettingsItem(scale), // Add this line

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

  /// About settings item - MOVED: Now part of App Settings section
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

  // Add this new method to your _SettingsTabState class
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

  // Add this method to show the confirmation dialog
void _showClearHistoryDialog() async {
  final result = await showOkCancelAlertDialog(
    context: context,
    title: 'Clear Call History',
    message: 'Are you sure you want to delete all call history?',
    okLabel: 'Clear',
    cancelLabel: 'Cancel',
    isDestructiveAction: true,
  );

  if (result == OkCancelResult.ok) {
    try {
      await CallHistoryManager.clearHistory();
      await showOkAlertDialog(
        context: context,
        title: 'Success',
        message: 'Call history cleared successfully.',
      );
    } catch (error) {
      await showOkAlertDialog(
        context: context,
        title: 'Error',
        message: 'Failed to clear call history.',
      );
    }
  }
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

  /// Navigate to configuration page
  void _navigateToConfigurationPage(SipService sipService) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfigurationPage(sipService: sipService),
      ),
    );
  }
}

// ConfigurationPage class - UPDATED with Server Connection Toggle
class ConfigurationPage extends StatefulWidget {
  final SipService sipService;

  const ConfigurationPage({super.key, required this.sipService});

  @override
  State<ConfigurationPage> createState() => _ConfigurationPageState();
}

class _ConfigurationPageState extends State<ConfigurationPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _serverController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _domainController;
  late TextEditingController _portController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  /// Initialize text controllers with current SIP settings
  void _initializeControllers() {
    _serverController = TextEditingController(
      text: widget.sipService.sipServer,
    );
    _usernameController = TextEditingController(
      text: widget.sipService.username,
    );
    _passwordController = TextEditingController(
      text: widget.sipService.password,
    );
    _domainController = TextEditingController(text: widget.sipService.domain);
    _portController = TextEditingController(
      text: widget.sipService.port.toString(),
    );
  }

  /// Dispose all text controllers
  void _disposeControllers() {
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _domainController.dispose();
    _portController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemes.getSettingsBackgroundColor(context),
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  /// Build app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppThemes.getSettingsBackgroundColor(context),
      elevation: 0,
      leading: _buildBackButton(),
      title: _buildAppBarTitle(),
      centerTitle: true,
    );
  }

  /// Back button
  Widget _buildBackButton() {
    return IconButton(
      icon: Icon(
        Icons.arrow_back_ios,
        color: Theme.of(context).colorScheme.primary,
        size: 20,
      ),
      onPressed: () => Navigator.pop(context),
    );
  }

  /// App bar title
  Widget _buildAppBarTitle() {
    return Text(
      'Account Settings',
      style: TextStyle(
        color: Theme.of(context).colorScheme.onBackground,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Build main body
  Widget _buildBody() {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = _calculateScale(constraints);
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SizedBox(height: 20 * scale),
                    _buildAccountInformationSection(scale),
                    SizedBox(height: 32 * scale),
                    // NEW: Server Connection Section
                    _buildServerConnectionSection(scale),
                    SizedBox(height: 32 * scale),
                    // Debug Commands Section
                    _buildDebugCommandsSection(scale),
                    SizedBox(height: 35 * scale),
                    _buildDangerZoneSection(scale),
                    SizedBox(height: 50 * scale),
                  ],
                ),
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

  Widget _buildAccountInformationSection(double scale) {
    return _buildNativeSection(
      title: 'Account Information',
      children: [
        _buildInfoRow('Account Name', _getAccountNameDisplay(), scale: scale),
        _buildInfoRow('Organization', _getOrganizationDisplay(), scale: scale),
        _buildInfoRow('Extension', _getExtensionDisplay(), scale: scale),
        // Wrap Server Status row in Consumer to listen for status changes
        Consumer<SipService>(
          builder: (context, sipService, child) {
            return _buildInfoRow(
              'Server Status',
              _getServerStatusDisplay(),
              statusColor: _getConnectionStatusColor(),
              scale: scale,
            );
          },
        ),
      ],
      scale: scale,
    );
  }

  /// NEW: Server Connection Section
  Widget _buildServerConnectionSection(double scale) {
    return _buildNativeSection(
      title: 'Server Connection',
      children: [_buildServerConnectionToggle(scale)],
      scale: scale,
    );
  }

  /// NEW: Server Connection Toggle Item
  Widget _buildServerConnectionToggle(double scale) {
    return Consumer<SipService>(
      builder: (context, sipService, child) {
        final isConnected = sipService.status == SipConnectionStatus.connected;
        final isConnecting =
            sipService.status == SipConnectionStatus.connecting;

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
                    sipService.status,
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8 * scale),
                ),
                child: Icon(
                  _getConnectionToggleIcon(sipService.status),
                  color: _getConnectionToggleIconColor(sipService.status),
                  size: 20 * scale,
                ),
              ),

              SizedBox(width: 12 * scale),

              // Connection Text
              Expanded(
                child: Text(
                  'Server Connection',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
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
      },
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

  /// NEW: Handle connection toggle
  Future<void> _handleConnectionToggle(
    bool value,
    SipService sipService,
  ) async {
    try {
      if (value) {
        // Connect to server using register method
        print('🔌 [ConfigurationPage] Connecting to SIP server...');

        // Check if settings are configured
        if (sipService.sipServer.isEmpty ||
            sipService.username.isEmpty ||
            sipService.password.isEmpty) {
          print('❌ [ConfigurationPage] SIP settings not configured');
          return;
        }

        await sipService.register();
        print('✅ [ConfigurationPage] Connection attempt completed');
      } else {
        // Disconnect from server using unregister method
        print('🔌 [ConfigurationPage] Disconnecting from SIP server...');
        await sipService.unregister();
        print('✅ [ConfigurationPage] Disconnection completed');
      }
    } catch (e) {
      print('❌ [ConfigurationPage] Connection toggle error: $e');
    }
  }

  // Debug Commands Section
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
                _buildDebugIcon(scale),
                SizedBox(width: 12 * scale),
                _buildDebugText(),
                _buildDebugChevron(scale),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Debug icon
  Widget _buildDebugIcon(double scale) {
    return Container(
      padding: EdgeInsets.all(6 * scale),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6 * scale),
      ),
      child: Icon(Icons.terminal, color: Colors.orange, size: 18 * scale),
    );
  }

  /// Debug text
  Widget _buildDebugText() {
    return Expanded(
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
    );
  }

  /// Debug chevron
  Widget _buildDebugChevron(double scale) {
    return Icon(
      CupertinoIcons.right_chevron,
      color: AppThemes.getSecondaryTextColor(context),
      size: 20 * scale,
    );
  }

  /// Navigate to debug page
  void _navigateToDebugPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DebugConnectionPage()),
    );
  }

  String _getAccountNameDisplay() {
    return widget.sipService.accountName.isNotEmpty
        ? widget.sipService.accountName
        : 'Not configured';
  }

  String _getOrganizationDisplay() {
    return widget.sipService.organization.isNotEmpty
        ? widget.sipService.organization
        : 'Not configured';
  }

  /// Get extension display text
  String _getExtensionDisplay() {
    return widget.sipService.username.isNotEmpty
        ? widget.sipService.username
        : 'Not configured';
  }

  /// Get server status display text
  String _getServerStatusDisplay() {
    switch (widget.sipService.status) {
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

  /// Get connection status color
  Color? _getConnectionStatusColor() {
    switch (widget.sipService.status) {
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

  /// Danger Zone Section
  Widget _buildDangerZoneSection(double scale) {
    return _buildNativeSection(
      title: 'Danger Zone',
      children: [_buildDeleteAccountItem(scale)],
      scale: scale,
    );
  }

  /// Delete account item
  Widget _buildDeleteAccountItem(double scale) {
    return Container(
      decoration: BoxDecoration(
        color: AppThemes.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(10 * scale),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10 * scale),
          onTap: _showDeleteAccountDialog,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16 * scale,
              vertical: 12 * scale,
            ),
            child: Row(
              children: [
                _buildDeleteIcon(scale),
                SizedBox(width: 12 * scale),
                _buildDeleteText(),
                _buildDeleteChevron(scale),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Delete icon
  Widget _buildDeleteIcon(double scale) {
    return Container(
      padding: EdgeInsets.all(6 * scale),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6 * scale),
      ),
      child: Icon(CupertinoIcons.delete, color: Colors.red, size: 18 * scale),
    );
  }

  /// Delete text
  Widget _buildDeleteText() {
    return const Expanded(
      child: Text(
        'Delete Account',
        style: TextStyle(
          color: Colors.red,
          fontSize: 17,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  /// Delete chevron
  Widget _buildDeleteChevron(double scale) {
    return Icon(
      CupertinoIcons.right_chevron,
      color: AppThemes.getSecondaryTextColor(context),
      size: 20 * scale,
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
        _buildSectionTitle(title, scale),
        _buildSectionContent(children, scale),
      ],
    );
  }

  /// Section title
  Widget _buildSectionTitle(String title, double scale) {
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

  /// Section content container
  Widget _buildSectionContent(List<Widget> children, double scale) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16 * scale),
      decoration: BoxDecoration(
        color: AppThemes.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(10 * scale),
      ),
      child: Column(children: children),
    );
  }

  /// Info row builder
  Widget _buildInfoRow(
    String label,
    String value, {
    Color? statusColor,
    required double scale,
  }) {
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
          _buildInfoLabel(label, scale),
          _buildInfoValue(value, statusColor, scale),
        ],
      ),
    );
  }

  /// Info label
  Widget _buildInfoLabel(String label, double scale) {
    return Text(
      label,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 17 * scale,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  /// Info value
  Widget _buildInfoValue(String value, Color? statusColor, double scale) {
    return Flexible(
      child: Text(
        value,
        style: TextStyle(
          color: statusColor ?? AppThemes.getSecondaryTextColor(context),
          fontSize: 17 * scale,
          fontWeight: FontWeight.w400,
        ),
        textAlign: TextAlign.end,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Show delete account dialog
void _showDeleteAccountDialog() async {
  final result = await showOkCancelAlertDialog(
    context: context,
    title: 'Delete Account',
    message:
        'Are you sure you want to delete this account? This will remove all saved settings and disconnect from the SIP server.',
    okLabel: 'Delete',
    cancelLabel: 'Cancel',
    isDestructiveAction: true, 
  );

  if (result == OkCancelResult.ok) {
    try {
  // todo

      await showOkAlertDialog(
        context: context,
        title: 'Account Deleted',
        message: 'The account was successfully removed.',
      );
    } catch (error) {
      await showOkAlertDialog(
        context: context,
        title: 'Error',
        message: 'Failed to delete the account. Please try again.',
      );
    }
  }
}




}
