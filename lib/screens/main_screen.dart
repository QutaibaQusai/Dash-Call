import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/sip_service.dart';
import '../widgets/call_controls.dart';
import 'contacts_tab.dart';
import 'history_tab.dart';
import 'settings_tab.dart';
import 'dialer_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  // Define the gradient colors
  static const Color gradientStart = Color(0xFF1501FF);
  static const Color gradientEnd = Color(0xFF00A3FF);
  
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment(-0.05, -1.0), // 183 degrees approximation
    end: Alignment(0.05, 1.0),
    colors: [gradientStart, gradientEnd],
  );

  @override
  Widget build(BuildContext context) {
    return Consumer<SipService>(
      builder: (context, sipService, child) {
        // If there's an active call, show call controls instead
        if (sipService.callStatus != CallStatus.idle) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: CallControls(sipService: sipService),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildAppBar(sipService),
          body: _buildBody(),
          bottomNavigationBar: _buildBottomNavigationBar(),
          floatingActionButton: _buildDialerFAB(),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(SipService sipService) {
    final List<String> titles = ['Contacts', 'History', 'Settings'];
    
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      shadowColor: Colors.black12,
      centerTitle: false,
      title: Text(
        titles[_currentIndex],
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 28,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        // Connection status indicator
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getConnectionStatusColor(sipService.status),
               
              ),
            ),
            onPressed: sipService.isConnecting ? null : () async {
              if (sipService.status == SipConnectionStatus.connected) {
                await sipService.unregister();
              } else {
                await sipService.register();
              }
            },
          ),
        ),
        
        // Menu button
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.black54),
          onSelected: (value) {
            if (value == 'logout') {
              _logout();
            } else if (value == 'connection') {
              _showConnectionInfo(sipService);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'connection',
              child: Row(
                children: [
                  Icon(
                    _getConnectionStatusIcon(sipService.status),
                    color: _getConnectionStatusColor(sipService.status),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(_getConnectionStatusText(sipService.status)),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red, size: 20),
                  SizedBox(width: 12),
                  Text('Logout', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const ContactsTab();
      case 1:
        return const HistoryTab();
      case 2:
        return const SettingsTab();
      default:
        return const ContactsTab();
    }
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
    
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: Color(0XFF0077f9),
        unselectedItemColor: Colors.grey.shade600,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts_outlined),
            activeIcon: Icon(Icons.contacts),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildDialerFAB() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: primaryGradient,
        borderRadius: BorderRadius.circular(32),
   
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(32),
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DialerScreen(),
              ),
            );
          },
          child: const Center(
            child: Icon(
              Icons.dialpad,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
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
        return Colors.grey.shade400;
    }
  }

  IconData _getConnectionStatusIcon(SipConnectionStatus status) {
    switch (status) {
      case SipConnectionStatus.connected:
        return Icons.wifi;
      case SipConnectionStatus.connecting:
        return Icons.wifi_outlined;
      case SipConnectionStatus.error:
        return Icons.wifi_off;
      case SipConnectionStatus.disconnected:
        return Icons.wifi_off_outlined;
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
        return 'Not Connected';
    }
  }

  void _showConnectionInfo(SipService sipService) {
    String message = '';
    Color color = Colors.grey;
    
    switch (sipService.status) {
      case SipConnectionStatus.connected:
        message = 'Connected to ${sipService.sipServer}';
        color = Colors.green;
        break;
      case SipConnectionStatus.connecting:
        message = 'Connecting to ${sipService.sipServer}...';
        color = Colors.orange;
        break;
      case SipConnectionStatus.error:
        message = sipService.errorMessage ?? 'Connection failed';
        color = Colors.red;
        break;
      case SipConnectionStatus.disconnected:
        message = 'Not connected. Configure settings to connect.';
        color = Colors.grey;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Are you sure you want to logout? You will need to scan a QR code again to login.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      print('🚪 [MainScreen] User confirmed logout');
      
      // Disconnect from SIP if connected
      final sipService = Provider.of<SipService>(context, listen: false);
      if (sipService.status == SipConnectionStatus.connected) {
        await sipService.unregister();
      }

      // Clear login status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      
      print('✅ [MainScreen] Logout completed, navigating to QR login');
      
      // Navigate back to QR login screen
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/qr-login',
          (route) => false,
        );
      }
    }
  }
}