import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      print('🔘 [UI] Button status check: ${sipService.status}');
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
          print('🔘 [UI] Button pressed! Current status: ${sipService.status}');
          if (sipService.status == SipConnectionStatus.connected) {
            print('🔘 [UI] Disconnecting...');
            await sipService.unregister();
          } else {
            print('🔘 [UI] Connecting...');
            // Add a small delay if we just disconnected
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
],
   
      ),
      body: Consumer<SipService>(
        builder: (context, sipService, child) {
          return Column(
            children: [
              // Status Display
              StatusDisplay(sipService: sipService),
              
              // Phone Number Input
              if (sipService.callStatus == CallStatus.idle)
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
              
              // Call Controls or Dialer
              Expanded(
                child: sipService.callStatus == CallStatus.idle
                    ? Column(
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
                      )
                    : CallControls(sipService: sipService),
              ),
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
}