
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/sip_service.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _serverController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _domainController;
  late TextEditingController _portController;
  
  bool _isPasswordVisible = false;
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  // Settings state
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _audioQuality = 'High';
  String _theme = 'Light';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _loadSettings();
    _loadAppSettings();
  }

  @override
  void dispose() {
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _domainController.dispose();
    _portController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _loadSettings() {
    final sipService = Provider.of<SipService>(context, listen: false);
    _serverController = TextEditingController(text: sipService.sipServer);
    _usernameController = TextEditingController(text: sipService.username);
    _passwordController = TextEditingController(text: sipService.password);
    _domainController = TextEditingController(text: sipService.domain);
    _portController = TextEditingController(text: sipService.port.toString());
  }

  Future<void> _loadAppSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      _audioQuality = prefs.getString('audio_quality') ?? 'High';
      _theme = prefs.getString('theme') ?? 'Light';
    });
  }

  Future<void> _saveAppSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('sound_enabled', _soundEnabled);
    await prefs.setBool('vibration_enabled', _vibrationEnabled);
    await prefs.setString('audio_quality', _audioQuality);
    await prefs.setString('theme', _theme);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SipService>(
      builder: (context, sipService, child) {
        return RefreshIndicator(
          onRefresh: () async {
            await _loadAppSettings();
            _loadSettings();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Connection Status Card
                _buildConnectionStatusCard(sipService),
                const SizedBox(height: 24),
                
                // SIP Configuration Section
                _buildSectionHeader(
                  'SIP Configuration',
                  Icons.settings_outlined,
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                      if (_isExpanded) {
                        _animationController.forward();
                      } else {
                        _animationController.reverse();
                      }
                    });
                  },
                  isExpandable: true,
                  isExpanded: _isExpanded,
                ),
                const SizedBox(height: 16),
                _buildSipConfigurationCard(sipService),
                const SizedBox(height: 24),
                
                // Call Settings Section
                // _buildSectionHeader('Call Settings', Icons.call_outlined),
                // const SizedBox(height: 16),
                // _buildCallSettingsCard(),
                // const SizedBox(height: 24),
                
                // // Notifications Section
                // _buildSectionHeader('Notifications', Icons.notifications_outlined),
                // const SizedBox(height: 16),
                // _buildNotificationSettingsCard(),
                // const SizedBox(height: 24),
                
                // // Advanced Settings Section
                // _buildSectionHeader('Advanced', Icons.tune_outlined),
                // const SizedBox(height: 16),
                // _buildAdvancedSettingsCard(),
                // const SizedBox(height: 24),
                
                // // About Section
                // _buildSectionHeader('About', Icons.info_outline),
                // const SizedBox(height: 16),
                // _buildAboutCard(),
                
                // // Add some bottom padding
                // const SizedBox(height: 100),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {VoidCallback? onTap, bool isExpandable = false, bool isExpanded = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment(-0.05, -1.0),
                end: Alignment(0.05, 1.0),
                colors: [Color(0xFF1501FF), Color(0xFF00A3FF)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
          if (isExpandable)
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.expand_more,
                color: Colors.grey.shade600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatusCard(SipService sipService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getConnectionStatusColor(sipService.status).withOpacity(0.1),
            _getConnectionStatusColor(sipService.status).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getConnectionStatusColor(sipService.status).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: _getConnectionStatusColor(sipService.status).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _getConnectionStatusColor(sipService.status),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Icon(
                  _getConnectionStatusIcon(sipService.status),
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getConnectionStatusTitle(sipService.status),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getConnectionStatusSubtitle(sipService),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (sipService.status != SipConnectionStatus.connected && 
              sipService.sipServer.isNotEmpty) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment(-0.05, -1.0),
                    end: Alignment(0.05, 1.0),
                    colors: [Color(0xFF1501FF), Color(0xFF00A3FF)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: sipService.isConnecting ? null : () => sipService.register(),
                    child: Center(
                      child: sipService.isConnecting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.wifi, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Connect Now',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSipConfigurationCard(SipService sipService) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Always visible summary
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sipService.sipServer.isNotEmpty ? sipService.sipServer : 'Not configured',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (sipService.username.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'User: ${sipService.username}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
            
            // Expandable configuration form
            if (_isExpanded) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildInputField(
                        controller: _serverController,
                        label: 'Server Address',
                        hint: 'sip.example.com',
                        icon: Icons.dns,
                        validator: (value) => value?.isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildInputField(
                              controller: _usernameController,
                              label: 'Username',
                              hint: '1001',
                              icon: Icons.person,
                              validator: (value) => value?.isEmpty == true ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInputField(
                              controller: _portController,
                              label: 'Port',
                              hint: '8088',
                              icon: Icons.settings_ethernet,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value?.isEmpty == true) return 'Required';
                                final port = int.tryParse(value!);
                                return (port == null || port < 1 || port > 65535) ? 'Invalid' : null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      _buildInputField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Enter password',
                        icon: Icons.lock,
                        obscureText: !_isPasswordVisible,
                        suffixIcon: IconButton(
                          icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                        validator: (value) => value?.isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      _buildInputField(
                        controller: _domainController,
                        label: 'Domain (Optional)',
                        hint: 'Leave empty to use server',
                        icon: Icons.domain,
                      ),
                      const SizedBox(height: 24),
                      
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                _loadSettings();
                                setState(() {
                                  _isExpanded = false;
                                  _animationController.reverse();
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment(-0.05, -1.0),
                                  end: Alignment(0.05, 1.0),
                                  colors: [Color(0xFF1501FF), Color(0xFF00A3FF)],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () => _saveConfiguration(sipService),
                                  child: const Center(
                                    child: Text(
                                      'Save & Connect',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCallSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            icon: Icons.volume_up_outlined,
            title: 'Call Sounds',
            subtitle: 'Ringtones and call tones',
            value: _soundEnabled,
            onChanged: (value) {
              setState(() => _soundEnabled = value);
              _saveAppSettings();
            },
          ),
          _buildDivider(),
          _buildSwitchTile(
            icon: Icons.vibration,
            title: 'Vibration',
            subtitle: 'Vibrate for incoming calls',
            value: _vibrationEnabled,
            onChanged: (value) {
              setState(() => _vibrationEnabled = value);
              _saveAppSettings();
            },
          ),
          _buildDivider(),
          _buildDropdownTile(
            icon: Icons.high_quality_outlined,
            title: 'Audio Quality',
            subtitle: 'Call audio quality setting',
            value: _audioQuality,
            options: const ['Low', 'Medium', 'High', 'Ultra'],
            onChanged: (value) {
              setState(() => _audioQuality = value!);
              _saveAppSettings();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
   
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            icon: Icons.notifications_active_outlined,
            title: 'Call Notifications',
            subtitle: 'Show incoming call notifications',
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
              _saveAppSettings();
            },
          ),
          _buildDivider(),
          _buildTappableTile(
            icon: Icons.notification_important_outlined,
            title: 'Notification Settings',
            subtitle: 'Open system notification settings',
            onTap: () {
              // TODO: Open system notification settings
              _showNotImplementedDialog('System notification settings');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTappableTile(
            icon: Icons.network_check,
            title: 'Network Diagnostics',
            subtitle: 'Test network connectivity',
            onTap: () => _showNetworkDiagnostics(),
          ),
          _buildDivider(),
          _buildTappableTile(
            icon: Icons.bug_report_outlined,
            title: 'Debug Logs',
            subtitle: 'View application logs',
            onTap: () => _showDebugLogs(),
          ),
          _buildDivider(),
          _buildTappableTile(
            icon: Icons.refresh,
            title: 'Reset Settings',
            subtitle: 'Reset all settings to default',
            onTap: () => _showResetDialog(),
            destructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoTile(
            icon: Icons.info_outline,
            title: 'App Version',
            subtitle: '1.0.0 (Build 1)',
          ),
          _buildDivider(),
          _buildTappableTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help with DashCall',
            onTap: () => _showNotImplementedDialog('Help & Support'),
          ),
          _buildDivider(),
          _buildTappableTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'View our privacy policy',
            onTap: () => _showNotImplementedDialog('Privacy Policy'),
          ),
          _buildDivider(),
          _buildTappableTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            subtitle: 'View terms of service',
            onTap: () => _showNotImplementedDialog('Terms of Service'),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF1501FF)),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1501FF), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Icon(icon, color: const Color(0xFF1501FF)),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF1501FF),
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Icon(icon, color: const Color(0xFF1501FF)),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        underline: const SizedBox.shrink(),
        items: options.map((option) {
          return DropdownMenuItem(
            value: option,
            child: Text(option),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTappableTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Icon(
        icon, 
        color: destructive ? Colors.red : const Color(0xFF1501FF),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: destructive ? Colors.red : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right, 
        color: Colors.grey.shade400,
      ),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Icon(icon, color: const Color(0xFF1501FF)),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade200,
      indent: 60,
    );
  }

  // Helper methods
  Color _getConnectionStatusColor(SipConnectionStatus status) {
    switch (status) {
      case SipConnectionStatus.connected:
        return Colors.green;
      case SipConnectionStatus.connecting:
        return Colors.orange;
      case SipConnectionStatus.error:
        return Colors.red;
      case SipConnectionStatus.disconnected:
        return Colors.grey.shade500;
    }
  }

  IconData _getConnectionStatusIcon(SipConnectionStatus status) {
    switch (status) {
      case SipConnectionStatus.connected:
        return Icons.check_circle;
      case SipConnectionStatus.connecting:
        return Icons.sync;
      case SipConnectionStatus.error:
        return Icons.error;
      case SipConnectionStatus.disconnected:
        return Icons.wifi_off;
    }
  }

  String _getConnectionStatusTitle(SipConnectionStatus status) {
    switch (status) {
      case SipConnectionStatus.connected:
        return 'Connected';
      case SipConnectionStatus.connecting:
        return 'Connecting...';
      case SipConnectionStatus.error:
        return 'Connection Failed';
      case SipConnectionStatus.disconnected:
        return 'Not Connected';
    }
  }

  String _getConnectionStatusSubtitle(SipService sipService) {
    switch (sipService.status) {
      case SipConnectionStatus.connected:
        return 'Connected to ${sipService.sipServer}';
      case SipConnectionStatus.connecting:
        return 'Connecting to ${sipService.sipServer}...';
      case SipConnectionStatus.error:
        return sipService.errorMessage ?? 'Check your settings and try again';
      case SipConnectionStatus.disconnected:
        return sipService.sipServer.isEmpty 
            ? 'Configure your SIP settings below'
            : 'Tap Connect to establish connection';
    }
  }

  void _saveConfiguration(SipService sipService) async {
    if (!_formKey.currentState!.validate()) return;

    await sipService.saveSettings(
      _serverController.text.trim(),
      _usernameController.text.trim(),
      _passwordController.text.trim(),
      _domainController.text.trim(),
      int.parse(_portController.text.trim()),
    );

    if (mounted) {
      setState(() {
        _isExpanded = false;
        _animationController.reverse();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Settings saved successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      
      final success = await sipService.register();
      
      if (mounted && !success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('⚠️ Settings saved but connection failed'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showNetworkDiagnostics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Network Diagnostics'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Network Status: Connected'),
            SizedBox(height: 8),
            Text('WiFi Signal: Strong'),
            SizedBox(height: 8),
            Text('Internet: Available'),
            SizedBox(height: 8),
            Text('SIP Port: Accessible'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDebugLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Logs'),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: const SingleChildScrollView(
            child: Text(
              'SIP Service initialized\n'
              'Attempting connection to server\n'
              'Registration successful\n'
              'Call initiated\n'
              'Media stream established\n'
              '...\n'
              'Debug logs would appear here',
              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'This will reset all settings to default values. This action cannot be undone.\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _resetAllSettings();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    // Reset controllers
    _serverController.clear();
    _usernameController.clear();
    _passwordController.clear();
    _domainController.clear();
    _portController.text = '8088';
    
    // Reset app settings
    setState(() {
      _notificationsEnabled = true;
      _soundEnabled = true;
      _vibrationEnabled = true;
      _audioQuality = 'High';
      _theme = 'Light';
    });
    
    await _saveAppSettings();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🔄 All settings have been reset'),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showNotImplementedDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: Text('$feature will be implemented in a future version.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}