import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sip_service.dart';

class DialerTab extends StatefulWidget {
  const DialerTab({super.key});

  @override
  State<DialerTab> createState() => _DialerTabState();
}

class _DialerTabState extends State<DialerTab> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SipService>(
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
                  children: [
                    // Left spacer to center the call button
                    Expanded(child: Container()),
                    
                    // Call Button - Always centered
                    _buildCallButton(sipService),
                    
                    // Right side - Delete button or spacer
                    Expanded(
                      child: _phoneController.text.isNotEmpty
                          ? Align(
                              alignment: Alignment.centerRight,
                              child: _buildActionButton(
                                icon: Icons.backspace_outlined,
                                onTap: () {
                                  setState(() {
                                    if (_phoneController.text.isNotEmpty) {
                                      _phoneController.text = _phoneController.text
                                          .substring(0, _phoneController.text.length - 1);
                                    }
                                  });
                                },
                              ),
                            )
                          : Container(), // Empty container when no text
                    ),
                  ],
                ),
              ),
            ],
        );
      },
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
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
            splashColor: Colors.transparent,
  highlightColor: Colors.transparent,
  hoverColor: Colors.transparent,
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

      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
            splashColor: Colors.transparent,
  highlightColor: Colors.transparent,
  hoverColor: Colors.transparent,
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
        color:  const Color(0xFF34C759) ,
        shape: BoxShape.circle,
   
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        borderRadius: BorderRadius.circular(40),
        onTap: canCall ? () => _makeCall(sipService) : null,
        child: Icon(
            Icons.call,
            color:  Colors.white ,
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

  void _makeCall(SipService sipService) async {
    final number = _phoneController.text.trim();
    if (number.isNotEmpty) {
      final success = await sipService.makeCall(number);
      
      if (!success && mounted) {
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