// lib/screens/main_screen.dart - ENHANCED: Event-driven, no timer

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:dash_call/screens/dialer_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/multi_account_manager.dart';
import '../services/sip_service.dart';
import '../services/call_manager.dart'; // NEW IMPORT
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
    return Consumer2<MultiAccountManager, CallManager>(
      builder: (context, accountManager, callManager, child) {
        // ✅ IMMEDIATE: Check if we should show CallScreen
        if (callManager.shouldShowCallScreen && callManager.activeCallService != null) {
          print('📱 [MainScreen] Showing CallScreen for: ${callManager.activeCallService!.username}');
          return CallScreen(sipService: callManager.activeCallService!);
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
        // Connection status for all accounts
        if (accountManager.hasAccounts)
          _buildConnectionStatusRow(accountManager),
        
        // Account Switcher - show on all tabs except Settings
        if (_currentIndex != 3 && accountManager.hasAccounts) ...[
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: AccountSwitcherWidget(),
          ),
        ] else if (_currentIndex != 3 && !accountManager.hasAccounts) ...[
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildNoAccountIndicator(),
          ),
        ],
      ],
    );
  }

  // NEW: Show status for all accounts (dual-SIM style)
  Widget _buildConnectionStatusRow(MultiAccountManager accountManager) {
    final allServices = accountManager.allSipServices.values.toList();
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < allServices.length && i < 2; i++) ...[
          _buildConnectionStatusIndicator(allServices[i], i + 1),
          if (i < allServices.length - 1 && i < 1) const SizedBox(width: 4),
        ],
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildConnectionStatusIndicator(SipService sipService, int simNumber) {
    final statusIcon = _getConnectionStatusIcon(sipService.status);
    final statusColor = _getConnectionStatusColor(sipService.status);

    return GestureDetector(
      onTap: () => _showConnectionStatusDialog(sipService, simNumber),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: statusColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              statusIcon,
              color: statusColor,
              size: 14,
            ),
            Text(
              '$simNumber',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAccountIndicator() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = 3;
        });
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.orange.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: const Icon(
          CupertinoIcons.exclamationmark_triangle,
          color: Colors.orange,
          size: 16,
        ),
      ),
    );
  }

  IconData _getConnectionStatusIcon(SipConnectionStatus status) {
    switch (status) {
      case SipConnectionStatus.connecting:
        return CupertinoIcons.arrow_2_circlepath;
      case SipConnectionStatus.error:
        return CupertinoIcons.exclamationmark_circle;
      case SipConnectionStatus.disconnected:
        return CupertinoIcons.wifi_slash;
      case SipConnectionStatus.connected:
        return CupertinoIcons.wifi;
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

  Future<void> _showConnectionStatusDialog(SipService sipService, int simNumber) async {
    final statusText = _getConnectionStatusText(sipService.status);
    
    switch (sipService.status) {
      case SipConnectionStatus.connected:
        await showOkAlertDialog(
          context: context,
          title: 'SIM $simNumber - $statusText',
          message: 'Account is connected and ready to make calls.\n\nAccount: ${sipService.username}',
        );
        break;
        
      case SipConnectionStatus.connecting:
        await showOkAlertDialog(
          context: context,
          title: 'SIM $simNumber - $statusText',
          message: 'Connecting to server...\n\nAccount: ${sipService.username}',
        );
        break;
        
      case SipConnectionStatus.error:
        final result = await showOkCancelAlertDialog(
          context: context,
          title: 'SIM $simNumber - $statusText',
          message: 'Connection failed. Check your account settings and internet connection.\n\nAccount: ${sipService.username}',
          okLabel: 'Settings',
          cancelLabel: 'Cancel',
        );
        
        if (result == OkCancelResult.ok) {
          setState(() {
            _currentIndex = 3; 
          });
        }
        break;
        
      case SipConnectionStatus.disconnected:
        final result = await showOkCancelAlertDialog(
          context: context,
          title: 'SIM $simNumber - $statusText',
          message: 'Not connected to server. Check your internet connection.\n\nAccount: ${sipService.username}',
          okLabel: 'Settings',
          cancelLabel: 'Cancel',
        );
        
        if (result == OkCancelResult.ok) {
          setState(() {
            _currentIndex = 3; 
          });
        }
        break;
    }
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