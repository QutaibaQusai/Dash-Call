import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sip_service.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  @override
  Widget build(BuildContext context) {
    return Consumer<SipService>(
      builder: (context, sipService, child) {
        return Container(
          color: const Color(0xFFF2F2F7),
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

                        _buildSettingsSection(sipService, scale),

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
        color: Colors.white,
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
              color: Colors.black87,
            ),
          ),

          SizedBox(height: 8 * scale),

          // Settings Description
          Text(
            'Configure your SIP connection settings, manage your account preferences, and customize your calling experience.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14 * scale,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(SipService sipService, double scale) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
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
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2 * scale),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13 * scale,
                        color: Colors.grey.shade600,
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
      color: Colors.grey.shade600,
      size: 16 * scale,
    );
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
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFF007AFF),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Account Settings',
          style: TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Same proportional scaling for configuration page
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

                      // Account Info Section
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

                      // Delete Account Section
                      _buildNativeSection(
                        title: 'DANGER ZONE',
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
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
                                        color: const Color(0xFFC7C7CC),
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
              color: const Color(0xFF6D6D70),
              fontSize: 13 * scale,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16 * scale),
          decoration: BoxDecoration(
            color: Colors.white,
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
            color: const Color(0xFFC6C6C8).withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.black,
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
                color: statusColor ?? const Color(0xFF6D6D70),
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
          backgroundColor: const Color(0xFFF2F2F7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text(
            'Delete Account',
            style: TextStyle(
              color: Colors.black,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this account? This will remove all saved settings and disconnect from the SIP server.',
            style: TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF007AFF),
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
