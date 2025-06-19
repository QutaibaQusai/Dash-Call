import 'package:dash_call/screens/dialer_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sip_service.dart';
import '../screens/call_screen.dart'; // Import the new call screen
import 'contacts_tab.dart';
import 'history_tab.dart';
import 'settings_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0; 

  @override
  Widget build(BuildContext context) {
    return Consumer<SipService>(
      builder: (context, sipService, child) {
        // Show full-screen call interface when there's an active call
        if (sipService.callStatus != CallStatus.idle) {
          return CallScreen(sipService: sipService);
        }

        return Scaffold(
          backgroundColor: _currentIndex == 3 ? const Color(0xFFF2F2F7) : Colors.white,
          appBar: _buildAppBar(sipService),
          body: _buildBody(),
          bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(SipService sipService) {
    final List<String> titles = ['Dash Call', 'Contacts', 'History', 'Settings'];
    
    return AppBar(
      backgroundColor: _currentIndex == 3 ? const Color(0xFFF2F2F7) : Colors.white,
      elevation: 0,
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
      ],
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const DialerTab();
      case 1:
        return const ContactsTab();
      case 2:
        return const HistoryTab();
      case 3:
        return const SettingsTab();
      default:
        return const DialerTab();
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
        selectedItemColor: const Color(0xFF0077F9),
        unselectedItemColor: Colors.grey.shade600,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(
            icon: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.circle_grid_3x3),
                SizedBox(height: 3),
              ],
            ),
            activeIcon: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.circle_grid_3x3_fill),
                SizedBox(height: 3),
              ],
            ),
            label: 'Keypad',
          ),
          BottomNavigationBarItem(
            icon: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.person_2),
                SizedBox(height: 3),
              ],
            ),
            activeIcon: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.person_2_fill),
                SizedBox(height: 3),
              ],
            ),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(
            icon: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.time),
                SizedBox(height: 3),
              ],
            ),
            activeIcon: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.time_solid),
                SizedBox(height: 3),
              ],
            ),
            label: 'Recent',
          ),
          BottomNavigationBarItem(
            icon: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.settings),
                SizedBox(height: 3),
              ],
            ),
            activeIcon: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.settings_solid),
                SizedBox(height: 3),
              ],
            ),
            label: 'Settings',
          ),
        ],
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
}