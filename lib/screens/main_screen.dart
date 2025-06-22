// lib/screens/main_screen.dart - Updated with Account Switcher

import 'package:dash_call/screens/dialer_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/multi_account_manager.dart';
import '../services/sip_service.dart';
import '../screens/call_screen.dart';
import '../themes/app_themes.dart';
import '../widgets/account_switcher_widget.dart';
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
    return Consumer<MultiAccountManager>(
      builder: (context, accountManager, child) {
        // Check if any account has an active call
        final activeSipService = accountManager.activeSipService;
        
        // Check all accounts for incoming/active calls
        SipService? callingSipService;
        for (final sipService in accountManager.allSipServices.values) {
          if (sipService.callStatus != CallStatus.idle) {
            callingSipService = sipService;
            break;
          }
        }

        // Show call screen if any account has an active call
        if (callingSipService != null) {
          return CallScreen(sipService: callingSipService);
        }

        return Scaffold(
          backgroundColor: _getBackgroundColor(),
          appBar: _buildAppBar(accountManager),
          body: _buildBody(activeSipService),
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

  PreferredSizeWidget _buildAppBar(MultiAccountManager accountManager) {
    final List<String> titles = ['DashCall', 'Contacts', 'History', 'Settings'];
    
    return AppBar(
      backgroundColor: _getBackgroundColor(),
      elevation: 0,
      centerTitle: false,
      title: Text(
        titles[_currentIndex],
        style: TextStyle(
          color: Theme.of(context).colorScheme.onBackground,
          fontSize: 28,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        // Account Switcher - show on all tabs except Settings
        if (_currentIndex != 3 && accountManager.hasAccounts) ...[
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: AccountSwitcherWidget(),
          ),
        ],
      ],
    );
  }

  Widget _buildBody(SipService? activeSipService) {
    switch (_currentIndex) {
      case 0:
        return DialerTab(sipService: activeSipService);
      case 1:
        return const ContactsTab();
      case 2:
        return const HistoryTab();
      case 3:
        return const SettingsTab();
      default:
        return DialerTab(sipService: activeSipService);
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
          backgroundColor: Colors.transparent,
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