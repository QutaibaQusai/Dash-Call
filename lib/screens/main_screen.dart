// lib/screens/main_screen.dart - UPDATED: Connection status in app bar

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
        // FIXED: Better call status detection using shouldShowFlutterCallScreen
        SipService? callingSipService = _findServiceRequiringFlutterCallScreen(accountManager);

        // FIXED: Only show Flutter call screen when explicitly needed
        if (callingSipService != null) {
          print('📱 [MainScreen] Showing Flutter CallScreen for service: ${callingSipService.username}');
          return CallScreen(sipService: callingSipService);
        }

        final activeSipService = accountManager.activeSipService;

        return Scaffold(
          backgroundColor: _getBackgroundColor(),
          appBar: _buildAppBar(accountManager),
          body: _buildBody(activeSipService),
          bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
    );
  }

  // FIXED: Only return service if it should show Flutter call screen
  SipService? _findServiceRequiringFlutterCallScreen(MultiAccountManager accountManager) {
    for (final sipService in accountManager.allSipServices.values) {
      // FIXED: Use the new shouldShowFlutterCallScreen getter
      if (sipService.shouldShowFlutterCallScreen) {
        print('🔍 [MainScreen] Service ${sipService.username} requires Flutter call screen');
        print('   - Call Status: ${sipService.callStatus}');
        print('   - Should Show Flutter Screen: ${sipService.shouldShowFlutterCallScreen}');
        return sipService;
      }
    }
    
    // Also check for outgoing calls that need Flutter UI
    for (final sipService in accountManager.allSipServices.values) {
      if (sipService.callStatus == CallStatus.calling) {
        print('🔍 [MainScreen] Service ${sipService.username} has outgoing call - showing Flutter UI');
        return sipService;
      }
    }
    
    return null;
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
        // Connection status indicator
        if (accountManager.hasAccounts && accountManager.activeSipService != null)
          _buildConnectionStatusIndicator(accountManager.activeSipService!),
        
        // Account Switcher - show on all tabs except Settings
        if (_currentIndex != 3 && accountManager.hasAccounts) ...[
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: AccountSwitcherWidget(),
          ),
        ] else if (_currentIndex != 3 && !accountManager.hasAccounts) ...[
          // Show "No Account" indicator when no accounts are configured
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildNoAccountIndicator(),
          ),
        ],
      ],
    );
  }

  Widget _buildConnectionStatusIndicator(SipService sipService) {
    final statusIcon = _getConnectionStatusIcon(sipService.status);
    final statusColor = _getConnectionStatusColor(sipService.status);
    final statusText = _getConnectionStatusText(sipService.status);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _showConnectionStatusDialog(sipService),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: statusColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                statusIcon,
                color: statusColor,
                size: 16,
              ),
              if (sipService.status != SipConnectionStatus.connected) ...[
                const SizedBox(width: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoAccountIndicator() {
    return GestureDetector(
      onTap: () {
        // Navigate to settings to add account
        setState(() {
          _currentIndex = 3;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.orange.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning,
              color: Colors.orange,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              'No Account',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getConnectionStatusIcon(SipConnectionStatus status) {
    switch (status) {
      case SipConnectionStatus.connecting:
        return Icons.sync;
      case SipConnectionStatus.error:
        return Icons.error;
      case SipConnectionStatus.disconnected:
        return Icons.signal_wifi_off;
      case SipConnectionStatus.connected:
        return Icons.signal_wifi_4_bar;
    }
  }

  String _getConnectionStatusText(SipConnectionStatus status) {
    switch (status) {
      case SipConnectionStatus.connecting:
        return 'Connecting';
      case SipConnectionStatus.error:
        return 'Error';
      case SipConnectionStatus.disconnected:
        return 'Offline';
      case SipConnectionStatus.connected:
        return 'Online';
    }
  }

  Color _getConnectionStatusColor(SipConnectionStatus status) {
    switch (status) {
      case SipConnectionStatus.connecting:
        return Colors.orange;
      case SipConnectionStatus.error:
        return Colors.red;
      case SipConnectionStatus.disconnected:
        return Colors.grey;
      case SipConnectionStatus.connected:
        return Colors.green;
    }
  }

  void _showConnectionStatusDialog(SipService sipService) {
    final statusText = _getConnectionStatusText(sipService.status);
    final statusColor = _getConnectionStatusColor(sipService.status);
    
    String message;
    switch (sipService.status) {
      case SipConnectionStatus.connected:
        message = 'Account is connected and ready to make calls';
        break;
      case SipConnectionStatus.connecting:
        message = 'Connecting to server...';
        break;
      case SipConnectionStatus.error:
        message = 'Connection failed. Check your account settings and internet connection.';
        break;
      case SipConnectionStatus.disconnected:
        message = 'Not connected to server. Check your internet connection.';
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getConnectionStatusIcon(sipService.status),
              color: statusColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(statusText),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 8),
            Text(
              'Account: ${sipService.username}',
              style: TextStyle(
                color: AppThemes.getSecondaryTextColor(context),
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          if (sipService.status != SipConnectionStatus.connected)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // You can add retry logic here
                sipService;
              },
              child: const Text('Retry'),
            ),
        ],
      ),
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