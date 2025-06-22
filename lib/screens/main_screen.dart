import 'package:dash_call/screens/dialer_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sip_service.dart';
import '../screens/call_screen.dart';
import '../themes/app_themes.dart'; // ADD THIS
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
        if (sipService.callStatus != CallStatus.idle) {
          return CallScreen(sipService: sipService);
        }

        return Scaffold(
          backgroundColor: _getBackgroundColor(), // UPDATED: Use theme-aware background
          appBar: _buildAppBar(),
          body: _buildBody(),
          bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
    );
  }

  Color _getBackgroundColor() {
    if (_currentIndex == 3) {
      return AppThemes.getSettingsBackgroundColor(context);
    }
    return Theme.of(context).scaffoldBackgroundColor;
  }

  PreferredSizeWidget _buildAppBar() {
    final List<String> titles = ['DashCall', 'Contacts', 'History', 'Settings'];
    
    return AppBar(
      backgroundColor: _getBackgroundColor(), // UPDATED: Use theme-aware background
      elevation: 0,
      centerTitle: false,
      title: Text(
        titles[_currentIndex],
        style: TextStyle(
          color: Theme.of(context).colorScheme.onBackground, // UPDATED: Use theme color
          fontSize: 28,
          fontWeight: FontWeight.w600,
        ),
      ),
     
    
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
    decoration: BoxDecoration(
      color: _getBackgroundColor(), 
    ),
    child: Theme(
      data: Theme.of(context).copyWith(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent, // UPDATED: Make transparent so container color shows
        elevation: 0,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: AppThemes.getSecondaryTextColor(context),
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
    ),
  );
}
  

}