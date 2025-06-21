
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sip_service.dart';
import '../services/dtmf_audio_service.dart';
import '../themes/app_themes.dart'; 

class DialerTab extends StatefulWidget {
  const DialerTab({super.key});

  @override
  State<DialerTab> createState() => _DialerTabState();
}

class _DialerTabState extends State<DialerTab> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Optional: Preload DTMF sounds for better performance
    Future.microtask(() async {
      try {
        await DTMFAudioService.preloadSounds();
      } catch (e) {
        // Silent fail
      }
    });
  }

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
          color: Theme.of(context).scaffoldBackgroundColor, 
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate responsive dimensions
                final screenHeight = constraints.maxHeight;
                final screenWidth = constraints.maxWidth;

                // Responsive sizing
                final numberDisplayHeight = screenHeight * 0.15;
                final dialPadHeight = screenHeight * 0.65;
                final buttonAreaHeight = screenHeight * 0.20;

                // Button size based on screen width
                final buttonSize = (screenWidth - 60) / 3.5;
                final callButtonSize = buttonSize * 0.95;

                return Column(
                  children: [
                    // Number Display Area
                    Container(
                      height: numberDisplayHeight,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Center(
                        child: Text(
                          _phoneController.text.isEmpty
                              ? ''
                              : _formatPhoneNumber(_phoneController.text),
                          style: TextStyle(
                            fontSize: _getResponsiveFontSize(screenWidth),
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onBackground, // UPDATED: Use theme color
                            letterSpacing: 1.0,
                            fontFamily: '.SF UI Text',
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
                        height: dialPadHeight,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.08,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Row 1: 1, 2, 3
                            _buildDialerRow(
                              ['1', '2', '3'],
                              ['.', 'ABC', 'DEF'],
                              buttonSize,
                            ),

                            // Row 2: 4, 5, 6
                            _buildDialerRow(
                              ['4', '5', '6'],
                              ['GHI', 'JKL', 'MNO'],
                              buttonSize,
                            ),

                            // Row 3: 7, 8, 9
                            _buildDialerRow(
                              ['7', '8', '9'],
                              ['PQRS', 'TUV', 'WXYZ'],
                              buttonSize,
                            ),

                            // Row 4: *, 0, #
                            _buildDialerRow(
                              ['*', '0', '#'],
                              ['', '+', '.'],
                              buttonSize,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Button Area
                    Container(
                      height: buttonAreaHeight,
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(child: Container()),

                              _buildCallButton(sipService, callButtonSize),

                              Expanded(
                                child: _phoneController.text.isNotEmpty
                                    ? Padding(
                                        padding: const EdgeInsets.only(right: 40),
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: _buildDeleteButton(
                                            callButtonSize * 0.6,
                                          ),
                                        ),
                                      )
                                    : Container(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  double _getResponsiveFontSize(double screenWidth) {
    if (screenWidth < 350) {
      return 28;
    } else if (screenWidth < 400) {
      return 32;
    } else {
      return 38;
    }
  }

  Widget _buildDialerRow(
    List<String> numbers,
    List<String> letters,
    double buttonSize,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.asMap().entries.map((entry) {
        int index = entry.key;
        String number = entry.value;
        String letter = letters[index];

        return _buildDialerButton(number, letter, buttonSize);
      }).toList(),
    );
  }

  Widget _buildDialerButton(String number, String letters, double size) {
    final numberFontSize = size * 0.4;
    final letterFontSize = size * 0.12;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getDialerButtonColor(), // UPDATED: Use theme-aware color
        shape: BoxShape.circle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.1), // UPDATED: Use theme color
          highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.05), // UPDATED: Use theme color
          
          // Regular tap - Real DTMF sound!
          onTap: () async {
            // Play real DTMF audio tone (auto-initializes if needed)
            await DTMFAudioService.playDTMF(number);
            
            // Update phone number display
            setState(() {
              _phoneController.text += number;
            });
            
            // Send DTMF to active call
            _sendDTMFToCall(number);
          },
          
          // Long press - Longer DTMF tone
          onLongPress: () async {
            // Play longer DTMF tone
            await DTMFAudioService.playLongDTMF(number);
            
            // Add to display
            setState(() {
              _phoneController.text += number;
            });
            
            // Send to call
            _sendDTMFToCall(number);
          },
          
          child: Stack(
            children: [
              // Number
              Positioned(
                top: letters.isNotEmpty ? size * 0.22 : size * 0.35,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    number,
                    style: TextStyle(
                      fontSize: numberFontSize,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface, // UPDATED: Use theme color
                      height: 1.0,
                      fontFamily: '.SF UI Text',
                    ),
                  ),
                ),
              ),
              // Letters
              if (letters.isNotEmpty)
                Positioned(
                  bottom: size * 0.18,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      letters,
                      style: TextStyle(
                        fontSize: letterFontSize,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface, // UPDATED: Use theme color
                        letterSpacing: size * 0.02,
                        height: 1.0,
                        fontFamily: '.SF UI Text',
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ADD THIS: Get theme-aware dialer button color
  Color _getDialerButtonColor() {
    return Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF2C2C2E) 
        : const Color(0xFFE5E5E5);
  }

  // Send DTMF to active call
  void _sendDTMFToCall(String digit) {
    final sipService = Provider.of<SipService>(context, listen: false);
    if (sipService.callStatus == CallStatus.active) {
      sipService.sendDTMF(digit);
    }
  }

  Widget _buildCallButton(SipService sipService, double size) {
    final bool canCall = _phoneController.text.isNotEmpty &&
        sipService.status == SipConnectionStatus.connected;

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF34C85A), // Keep green for call button
        shape: BoxShape.circle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          onTap: canCall ? () => _makeCall(sipService) : null,
          child: Icon(
            CupertinoIcons.phone_fill,
            color: Colors.white,
            size: size * 0.4,
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(double size) {
    return GestureDetector(
      onTap: () async {
        // Stop any playing DTMF
        await DTMFAudioService.stopDTMF();
        
        setState(() {
          if (_phoneController.text.isNotEmpty) {
            _phoneController.text = _phoneController.text.substring(
              0,
              _phoneController.text.length - 1,
            );
          }
        });
      },
      onLongPress: () async {
        // Stop DTMF and clear all
        await DTMFAudioService.stopDTMF();
        
        setState(() {
          _phoneController.clear();
        });
      },
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: Icon(
          Icons.backspace,
          color: AppThemes.getSecondaryTextColor(context), // UPDATED: Use theme-aware color
          size: size * 0.55,
        ),
      ),
    );
  }

  String _formatPhoneNumber(String number) {
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
            backgroundColor: const Color(0xFFFF3B30),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
}