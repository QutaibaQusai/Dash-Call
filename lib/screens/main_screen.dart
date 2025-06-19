import 'package:dash_call/screens/dialer_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sip_service.dart';
import '../widgets/call_controls.dart';
import 'contacts_tab.dart';
import 'history_tab.dart';
import 'settings_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0; // Start with dialer tab
  


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
          backgroundColor:_currentIndex==3? const Color(0xFFF2F2F7):Colors.white,
          appBar: _buildAppBar(sipService),
          body: _buildBody(),
          bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(SipService sipService) {
    final List<String> titles = ['Dialer', 'Contacts', 'History', 'Settings',];
    
    return AppBar(
      backgroundColor:_currentIndex==3? const Color(0xFFF2F2F7):Colors.white,
      
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
        selectedItemColor: Color(0XFF0077f9),
        unselectedItemColor: Colors.grey.shade600,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dialpad_outlined),
            activeIcon: Icon(Icons.dialpad),
            label: 'Dialer',
          ),
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