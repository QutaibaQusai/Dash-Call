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
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF007AFF), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Keypad',
          style: TextStyle(
            color: Colors.black,
            fontSize: 17,
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                child: Container(
                  height: 60,
                  alignment: Alignment.center,
                  child: Text(
                    _phoneController.text.isEmpty 
                        ? '' 
                        : _formatPhoneNumber(_phoneController.text),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 40,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              
              // Dialer Pad
              Expanded(
                child: _buildNativeDialerPad(),
              ),
              
              // Action Buttons
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Delete Button
                    _buildActionButton(
                      icon: Icons.backspace_outlined,
                      onTap: _phoneController.text.isNotEmpty ? () {
                        setState(() {
                          if (_phoneController.text.isNotEmpty) {
                            _phoneController.text = _phoneController.text
                                .substring(0, _phoneController.text.length - 1);
                          }
                        });
                      } : null,
                    ),
                    
                    // Call Button
                    _buildCallButton(sipService),
                    
                    // Add Contact Button
                    _buildActionButton(
                      icon: Icons.person_add_outlined,
                      onTap: _phoneController.text.isNotEmpty ? () {
                        // Add contact functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Add contact feature'),
                            backgroundColor: const Color(0xFF007AFF),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      } : null,
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

  Widget _buildConnectionStatus(SipService sipService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getConnectionStatusColor(sipService.status).withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _getConnectionStatusColor(sipService.status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
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
    );
  }

  Widget _buildNativeDialerPad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          // Row 1: 1, 2, 3
          _buildDialerRow(['1', '2', '3'], ['', 'ABC', 'DEF']),
          
          const SizedBox(height: 10),
          
          // Row 2: 4, 5, 6
          _buildDialerRow(['4', '5', '6'], ['GHI', 'JKL', 'MNO']),
          
          const SizedBox(height: 10),
          
          // Row 3: 7, 8, 9
          _buildDialerRow(['7', '8', '9'], ['PQRS', 'TUV', 'WXYZ']),
          
          const SizedBox(height: 10),
          
          // Row 4: *, 0, #
          _buildDialerRow(['*', '0', '#'], ['', '+', '']),
        ],
      ),
    );
  }

  Widget _buildDialerRow(List<String> numbers, List<String> letters) {
    return Row(
      children: numbers.asMap().entries.map((entry) {
        int index = entry.key;
        String number = entry.value;
        String letter = letters[index];
        
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: _buildDialerButton(number, letter),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDialerButton(String number, String letters) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          onTap: () {
            setState(() {
              _phoneController.text += number;
            });
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                number,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                ),
              ),
              if (letters.isNotEmpty)
                Text(
                  letters,
                  style: const TextStyle(
                    color: Color(0xFF6D6D70),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, VoidCallback? onTap}) {
    return Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        color: onTap != null ? Colors.white : Colors.white.withOpacity(0.5),
        shape: BoxShape.circle,
        boxShadow: onTap != null ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
            spreadRadius: 1,
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(32.5),
          onTap: onTap,
          child: Icon(
            icon,
            color: onTap != null ? const Color(0xFF6D6D70) : const Color(0xFF6D6D70).withOpacity(0.4),
            size: 26,
          ),
        ),
      ),
    );
  }

  Widget _buildCallButton(SipService sipService) {
    final bool canCall = _phoneController.text.isNotEmpty && 
                        sipService.status == SipConnectionStatus.connected;
    
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: canCall ? const Color(0xFF34C759) : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: canCall 
                ? const Color(0xFF34C759).withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: canCall ? 20 : 4,
            offset:  Offset(0, canCall ? 4 : 2),
            spreadRadius: canCall ? 2 : 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          onTap: canCall ? () => _makeCall(sipService) : null,
          child:           Icon(
            Icons.call,
            color: canCall ? Colors.white : const Color(0xFF6D6D70).withOpacity(0.3),
            size: 32,
          ),
        ),
      ),
    );
  }

  String _formatPhoneNumber(String number) {
    // Simple formatting for display
    if (number.length <= 3) {
      return number;
    } else if (number.length <= 6) {
      return '${number.substring(0, 3)} ${number.substring(3)}';
    } else if (number.length <= 10) {
      return '${number.substring(0, 3)} ${number.substring(3, 6)} ${number.substring(6)}';
    } else {
      return '${number.substring(0, 3)} ${number.substring(3, 6)} ${number.substring(6, 10)} ${number.substring(10)}';
    }
  }

  Color _getConnectionStatusColor(SipConnectionStatus status) {
    switch (status) {
      case SipConnectionStatus.connected:
        return const Color(0xFF34C759); // iOS green
      case SipConnectionStatus.connecting:
        return const Color(0xFFFF9F0A); // iOS orange
      case SipConnectionStatus.error:
        return const Color(0xFFFF3B30); // iOS red
      case SipConnectionStatus.disconnected:
        return const Color(0xFF8E8E93); // iOS gray
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

  void _makeCall(SipService sipService) async {
    final number = _phoneController.text.trim();
    if (number.isNotEmpty) {
      final success = await sipService.makeCall(number);
      
      if (success && mounted) {
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(sipService.errorMessage ?? 'Failed to make call'),
            backgroundColor: const Color(0xFFFF3B30),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }
}