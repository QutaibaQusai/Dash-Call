import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/sip_service.dart';
import '../widgets/sip_config_dialog.dart';
import '../widgets/dialer_pad.dart';
import '../widgets/call_controls.dart';
import '../widgets/status_display.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DashCall'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Consumer<SipService>(
            builder: (context, sipService, child) {
              return IconButton(
                icon: Icon(
                  sipService.status == SipConnectionStatus.connected
                      ? Icons.phone_enabled
                      : Icons.phone_disabled,
                  color: sipService.status == SipConnectionStatus.connected
                      ? Colors.green
                      : Colors.red,
                ),
                onPressed: sipService.isConnecting ? null : () async {
                  if (sipService.status == SipConnectionStatus.connected) {
                    await sipService.unregister();
                  } else {
                    if (sipService.status == SipConnectionStatus.disconnected) {
                      await Future.delayed(const Duration(milliseconds: 200));
                    }
                    await sipService.register();
                  }
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showConfigDialog(),
          ),
          // Logout button
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Consumer<SipService>(
        builder: (context, sipService, child) {
          return Column(
            children: [
              
              if (sipService.callStatus != CallStatus.idle)
                Expanded(
                  child: CallControls(sipService: sipService),
                )
              // Idle state - dialer
              else ...[
                // Phone Number Input
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      hintText: 'Enter phone number',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                
                // Dialer Pad and Call Button
                Expanded(
                  child: Column(
                    children: [
                      // Dialer Pad
                      Expanded(
                        child: DialerPad(
                          onNumberPressed: (number) {
                            _phoneController.text += number;
                          },
                          onDeletePressed: () {
                            if (_phoneController.text.isNotEmpty) {
                              _phoneController.text = _phoneController.text
                                  .substring(0, _phoneController.text.length - 1);
                            }
                          },
                        ),
                      ),
                      
                      // Call Button
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.call, size: 28),
                            label: const Text('Call', style: TextStyle(fontSize: 18)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: sipService.status == SipConnectionStatus.connected 
                                ? () => sipService.makeCall(_phoneController.text)
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
      floatingActionButton: Consumer<SipService>(
        builder: (context, sipService, child) {
          if (sipService.errorMessage != null) {
            return FloatingActionButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(sipService.errorMessage!),
                    backgroundColor: Colors.red,
                    action: SnackBarAction(
                      label: 'Dismiss',
                      onPressed: sipService.clearError,
                    ),
                  ),
                );
                sipService.clearError();
              },
              backgroundColor: Colors.red,
              child: const Icon(Icons.error),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }



  void _showConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => const SipConfigDialog(),
    );
  }

  // Logout functionality
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout? You will need to scan a QR code again to login.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
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
          (route) => false, // Remove all previous routes
        );
      }
    }
  }
}