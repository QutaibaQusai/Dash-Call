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
              
              // INCOMING CALL OVERLAY - This is the key fix!
              if (sipService.callStatus == CallStatus.incoming)
                Expanded(
                  child: _buildIncomingCallUI(sipService),
                )
              // ACTIVE/HELD/CALLING CALL CONTROLS  
              else if (sipService.callStatus != CallStatus.idle)
                Expanded(
                  child: CallControls(sipService: sipService),
                )
              // IDLE STATE - DIALER
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

  // NEW METHOD: Dedicated incoming call UI
  Widget _buildIncomingCallUI(SipService sipService) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Incoming call icon
          const Icon(
            Icons.phone_callback,
            size: 80,
            color: Colors.blue,
          ),
          
          const SizedBox(height: 24),
          
          // "Incoming Call" text
          Text(
            'Incoming Call',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Caller number/name
          if (sipService.callNumber != null)
            Text(
              sipService.callNumber!,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          
          const SizedBox(height: 48),
          
          // Accept/Reject buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // REJECT BUTTON
              Column(
                children: [
                  FloatingActionButton.large(
                    onPressed: () {
                      print('🔴 [UI] Reject button pressed');
                      sipService.rejectCall();
                    },
                    backgroundColor: Colors.red,
                    heroTag: "reject_incoming",
                    child: const Icon(
                      Icons.call_end, 
                      color: Colors.white, 
                      size: 36
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Reject',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              
              // ACCEPT BUTTON  
              Column(
                children: [
                  FloatingActionButton.large(
                    onPressed: () {
                      print('🟢 [UI] Accept button pressed');
                      sipService.answerCall();
                    },
                    backgroundColor: Colors.green,
                    heroTag: "accept_incoming",
                    child: const Icon(
                      Icons.call, 
                      color: Colors.white, 
                      size: 36
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Accept',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
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