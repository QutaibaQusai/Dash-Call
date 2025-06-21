
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sip_service.dart';
import '../services/theme_service.dart' as services; // ADD THIS
import '../widgets/theme_selector.dart'; // ADD THIS
import '../themes/app_themes.dart'; // ADD THIS

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<SipService, services.ThemeService>( // UPDATED: Listen to both services
      builder: (context, sipService, themeService, child) {
        return Container(
          color: AppThemes.getSettingsBackgroundColor(context), // UPDATED: Use theme-aware color
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Base dimensions for proportional scaling
                final baseWidth = 375.0; // iPhone SE base width
                final scaleWidth = constraints.maxWidth / baseWidth;
                final scaleHeight =
                    constraints.maxHeight / 667.0; // iPhone SE base height
                final scale = (scaleWidth + scaleHeight) / 2; // Average scale

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

                        // ADD THIS: App Settings Section
                        _buildAppSettingsSection(themeService, scale),

                        SizedBox(height: 32 * scale),

                        _buildAccountSettingsSection(sipService, scale),

                        SizedBox(height: 40 * scale),

                        // Extra padding for small screens
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

  Widget _buildHeaderContainer(double scale) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(16 * scale),
      padding: EdgeInsets.all(32 * scale),
      decoration: BoxDecoration(
        color: AppThemes.getCardBackgroundColor(context), // UPDATED: Use theme-aware color
        borderRadius: BorderRadius.circular(20 * scale),
      ),
      child: Column(
        children: [
          Container(
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
          ),

          SizedBox(height: 16 * scale),

          // Settings Title
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 28 * scale,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface, // UPDATED: Use theme color
            ),
          ),

          SizedBox(height: 8 * scale),

          // Settings Description
          Text(
            'Configure your SIP connection settings, manage your account preferences, and customize your calling experience.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14 * scale,
              color: AppThemes.getSecondaryTextColor(context), // UPDATED: Use theme-aware color
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ADD THIS: App Settings Section
  Widget _buildAppSettingsSection(services.ThemeService themeService, double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 8 * scale),
          child: Text(
            'APP SETTINGS',
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
            borderRadius: BorderRadius.circular(12 * scale),
          ),
          child: Column(
            children: [
              _buildSettingsItem(
                icon: CupertinoIcons.paintbrush,
                iconColor: Colors.purple,
                title: 'Appearance',
                subtitle: _getThemeDisplayText(themeService.themeMode),
                trailing: Icon(
                  Icons.chevron_right,
                  color: AppThemes.getSecondaryTextColor(context),
                  size: 16 * scale,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ThemeSelector(),
                    ),
                  );
                },
                scale: scale,
              ),

            ],
          ),
        ),
      ],
    );
  }

  // UPDATED: Renamed from _buildSettingsSection
  Widget _buildAccountSettingsSection(SipService sipService, double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 8 * scale),
          child: Text(
            'ACCOUNT',
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
            borderRadius: BorderRadius.circular(12 * scale),
          ),
          child: Column(
            children: [
              _buildSettingsItem(
                icon: CupertinoIcons.info,
                iconColor: Colors.blue,
                title: 'Account',
                subtitle:
                    sipService.username.isNotEmpty
                        ? sipService.username
                        : 'Not configured',
                trailing: _buildConnectionStatusBadge(sipService, scale),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => _ConfigurationPage(sipService: sipService),
                    ),
                  );
                },
                scale: scale,
              ),
            ],
          ),
        ),
      ],
    );
  }

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
              // Leading Icon
              Container(
                padding: EdgeInsets.all(8 * scale),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8 * scale),
                ),
                child: Icon(icon, color: iconColor, size: 20 * scale),
              ),

              SizedBox(width: 12 * scale),

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16 * scale,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface, // UPDATED: Use theme color
                      ),
                    ),
                    SizedBox(height: 2 * scale),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13 * scale,
                        color: AppThemes.getSecondaryTextColor(context), // UPDATED: Use theme-aware color
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              SizedBox(width: 8 * scale),

              // Trailing Widget
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatusBadge(SipService sipService, double scale) {
    return Icon(
      Icons.chevron_right,
      color: AppThemes.getSecondaryTextColor(context), // UPDATED: Use theme-aware color
      size: 16 * scale,
    );
  }

  // ADD THIS: Helper method to get theme display text
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


}

class _ConfigurationPage extends StatefulWidget {
  final SipService sipService;

  const _ConfigurationPage({required this.sipService});

  @override
  State<_ConfigurationPage> createState() => _ConfigurationPageState();
}

class _ConfigurationPageState extends State<_ConfigurationPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _serverController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _domainController;
  late TextEditingController _portController;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _domainController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _loadSettings() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemes.getSettingsBackgroundColor(context), 
      appBar: AppBar(
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
          'Account Settings',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onBackground, 
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final baseWidth = 375.0;
            final scaleWidth = constraints.maxWidth / baseWidth;
            final scaleHeight = constraints.maxHeight / 667.0;
            final scale = (scaleWidth + scaleHeight) / 2;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      SizedBox(height: 20 * scale),

                      _buildNativeSection(
                        title: 'ACCOUNT INFORMATION',
                        children: [
                          _buildNativeInfoRow(
                            'Server',
                            widget.sipService.sipServer.isNotEmpty
                                ? widget.sipService.sipServer
                                : 'Not configured',
                            scale: scale,
                          ),
                          _buildNativeInfoRow(
                            'Extension',
                            widget.sipService.username.isNotEmpty
                                ? widget.sipService.username
                                : 'Not configured',
                            scale: scale,
                          ),
                        ],
                        scale: scale,
                      ),

                      SizedBox(height: 35 * scale),

                      _buildNativeSection(
                        title: 'DANGER ZONE',
                        children: [
                          Container(
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
                                      Container(
                                        padding: EdgeInsets.all(6 * scale),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            6 * scale,
                                          ),
                                        ),
                                        child: Icon(
                                          CupertinoIcons.delete,
                                          color: Colors.red,
                                          size: 18 * scale,
                                        ),
                                      ),
                                      SizedBox(width: 12 * scale),
                                      Expanded(
                                        child: Text(
                                          'Delete Account',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 17 * scale,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        CupertinoIcons.right_chevron,
                                        color: AppThemes.getSecondaryTextColor(context), // UPDATED: Use theme-aware color
                                        size: 20 * scale,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        scale: scale,
                      ),

                      SizedBox(height: 50 * scale),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

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
              color: AppThemes.getSecondaryTextColor(context), // UPDATED: Use theme-aware color
              fontSize: 13 * scale,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16 * scale),
          decoration: BoxDecoration(
            color: AppThemes.getCardBackgroundColor(context), // UPDATED: Use theme-aware color
            borderRadius: BorderRadius.circular(10 * scale),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildNativeInfoRow(
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
            color: AppThemes.getDividerColor(context).withOpacity(0.3), // UPDATED: Use theme-aware color
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface, // UPDATED: Use theme color
              fontSize: 17 * scale,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Spacer(),
          if (statusColor != null)
            Container(
              width: 8 * scale,
              height: 8 * scale,
              margin: EdgeInsets.only(right: 8 * scale),
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: statusColor ?? AppThemes.getSecondaryTextColor(context), // UPDATED: Use theme-aware color
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

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppThemes.getCardBackgroundColor(context), // UPDATED: Use theme-aware color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Text(
            'Delete Account',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface, // UPDATED: Use theme color
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this account? This will remove all saved settings and disconnect from the SIP server.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface, // UPDATED: Use theme color
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary, // UPDATED: Use theme color
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // _deleteAccount();
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}