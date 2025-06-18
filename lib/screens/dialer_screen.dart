import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sip_service.dart';
import '../widgets/dialer_pad.dart';

class DialerScreen extends StatefulWidget {
  const DialerScreen({super.key});

  @override
  State<DialerScreen> createState() => _DialerScreenState();
}

class _DialerScreenState extends State<DialerScreen> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Dialer',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<SipService>(
        builder: (context, sipService, child) {
          return Column(
            children: [
              // Phone Number Display
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Number input field
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 2,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter number',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Connection status indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getConnectionStatusColor(sipService.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getConnectionStatusColor(sipService.status).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getConnectionStatusColor(sipService.status),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getConnectionStatusText(sipService.status),
                            style: TextStyle(
                              color: _getConnectionStatusColor(sipService.status),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Dialer Pad
              Expanded(
                child: DialerPad(
                  onNumberPressed: (number) {
                    setState(() {
                      _phoneController.text += number;
                    });
                  },
                  onDeletePressed: () {
                    setState(() {
                      if (_phoneController.text.isNotEmpty) {
                        _phoneController.text = _phoneController.text
                            .substring(0, _phoneController.text.length - 1);
                      }
                    });
                  },
                ),
              ),
              
              // Call Button
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Clear button (only show if there's text)
                    if (_phoneController.text.isNotEmpty) ...[
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _phoneController.clear();
                          });
                        },
                        icon: Icon(Icons.clear, color: Colors.grey.shade600),
                        label: Text(
                          'Clear',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Call button
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: _phoneController.text.isNotEmpty && 
                                  sipService.status == SipConnectionStatus.connected
                              ? const LinearGradient(
                                  begin: Alignment(-0.05, -1.0),
                                  end: Alignment(0.05, 1.0),
                                  colors: [Color(0xFF1501FF), Color(0xFF00A3FF)],
                                )
                              : null,
                          color: _phoneController.text.isEmpty || 
                                 sipService.status != SipConnectionStatus.connected
                              ? Colors.grey.shade300
                              : null,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: _phoneController.text.isNotEmpty && 
                                     sipService.status == SipConnectionStatus.connected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF1501FF).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(32),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(32),
                            onTap: _phoneController.text.isNotEmpty && 
                                   sipService.status == SipConnectionStatus.connected
                                ? () => _makeCall(sipService)
                                : null,
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.call,
                                    color: _phoneController.text.isNotEmpty && 
                                           sipService.status == SipConnectionStatus.connected
                                        ? Colors.white
                                        : Colors.grey.shade500,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _getCallButtonText(sipService),
                                    style: TextStyle(
                                      color: _phoneController.text.isNotEmpty && 
                                             sipService.status == SipConnectionStatus.connected
                                          ? Colors.white
                                          : Colors.grey.shade500,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
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

  String _getConnectionStatusText(SipConnectionStatus status) {
    switch (status) {
      case SipConnectionStatus.connected:
        return 'Ready to call';
      case SipConnectionStatus.connecting:
        return 'Connecting...';
      case SipConnectionStatus.error:
        return 'Connection error';
      case SipConnectionStatus.disconnected:
        return 'Not connected';
    }
  }

  String _getCallButtonText(SipService sipService) {
    if (_phoneController.text.isEmpty) {
      return 'Enter number';
    } else if (sipService.status != SipConnectionStatus.connected) {
      return 'Not connected';
    } else {
      return 'Call';
    }
  }

  void _makeCall(SipService sipService) async {
    final number = _phoneController.text.trim();
    if (number.isNotEmpty) {
      // Show loading state briefly
      final success = await sipService.makeCall(number);
      
      if (success && mounted) {
        // Navigate back to main screen where call controls will be shown
        Navigator.pop(context);
      } else if (mounted) {
        // Show error if call failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(sipService.errorMessage ?? 'Failed to make call'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }
}