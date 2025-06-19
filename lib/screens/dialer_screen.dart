import 'package:flutter/cupertino.dart';
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
        return Container(
          color: Colors.white,
          child: Column(
            children: [
              // Phone Number Display Area
              Container(
                height: 120,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Center(
                  child: Text(
                    _phoneController.text.isEmpty 
                        ? '' 
                        : _formatPhoneNumber(_phoneController.text),
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w600, // Much bolder like iOS
                      color: Colors.black,
                      letterSpacing: 1.0,
                      fontFamily: '.SF UI Text', // iOS system font
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              
              // Dialer Pad
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Row 1: 1, 2, 3
                      _buildDialerRow(['1', '2', '3'], ['', 'ABC', 'DEF']),
                      const SizedBox(height: 20),
                      
                      // Row 2: 4, 5, 6
                      _buildDialerRow(['4', '5', '6'], ['GHI', 'JKL', 'MNO']),
                      const SizedBox(height: 20),
                      
                      // Row 3: 7, 8, 9
                      _buildDialerRow(['7', '8', '9'], ['PQRS', 'TUV', 'WXYZ']),
                      const SizedBox(height: 20),
                      
                      // Row 4: *, 0, #
                      _buildDialerRow(['*', '0', '#'], ['', '+', '']),
                      
                      const SizedBox(height: 35),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(child: Container()),
                          
                          _buildCallButton(sipService),
                          
                          Expanded(
                            child: _phoneController.text.isNotEmpty
                                ? Padding(
                                  padding: const EdgeInsets.only(right: 40),
                                  child: Align(
                                      alignment: Alignment.centerRight,
                                      child: _buildDeleteButton(),
                                    ),
                                )
                                : Container(),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 40), 
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDialerRow(List<String> numbers, List<String> letters) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.asMap().entries.map((entry) {
        int index = entry.key;
        String number = entry.value;
        String letter = letters[index];
        
        return _buildDialerButton(number, letter);
      }).toList(),
    );
  }

  Widget _buildDialerButton(String number, String letters) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5E5), // Perfect iOS button gray
        shape: BoxShape.circle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          splashColor: Colors.black.withOpacity(0.1),
          highlightColor: Colors.black.withOpacity(0.05),
          onTap: () {
            setState(() {
              _phoneController.text += number;
            });
          },
          child: Container(
            width: 80,
            height: 80,
            child: Stack(
              children: [
                // Number - positioned in upper center
                Positioned(
                  top: letters.isNotEmpty ? 18 : 28,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      number,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w600, // Much bolder
                        color: Colors.black,
                        height: 1.0,
                        fontFamily: '.SF UI Text', // iOS system font
                      ),
                    ),
                  ),
                ),
                // Letters - positioned in lower center
                if (letters.isNotEmpty)
                  Positioned(
                    bottom: 15,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        letters,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800, // Extra bold
                          color: Colors.black,
                          letterSpacing: 2.0,
                          height: 1.0,
                          fontFamily: '.SF UI Text', // iOS system font
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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
        color:  const Color(0xFF34C85A), 
        shape: BoxShape.circle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(33),
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          onTap: canCall ? () => _makeCall(sipService) : null,
          child: Icon(
            CupertinoIcons.phone_fill,
            color: Colors.white,
            size: 35,
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_phoneController.text.isNotEmpty) {
            _phoneController.text = _phoneController.text
                .substring(0, _phoneController.text.length - 1);
          }
        });
      },
      onLongPress: () {
        setState(() {
          _phoneController.clear();
        });
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.backspace,
          color: const Color(0xFFE5E5E5),
          size: 28,
        ),
      ),
    );
  }

  String _formatPhoneNumber(String number) {
    // iOS-style phone number formatting
    if (number.length <= 3) {
      return number;
    } else if (number.length <= 6) {
      return '${number.substring(0, 3)}-${number.substring(3)}';
    } else if (number.length <= 10) {
      return '(${number.substring(0, 3)}) ${number.substring(3, 6)}-${number.substring(6)}';
    } else {
      return '+${number.substring(0, number.length - 10)} (${number.substring(number.length - 10, number.length - 7)}) ${number.substring(number.length - 7, number.length - 4)}-${number.substring(number.length - 4)}';
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
            backgroundColor: const Color(0xFFFF3B30), // iOS red
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }
}