// lib/screens/dialer_tab.dart - Rewritten with Clean Architecture

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
  
  // Dialer configuration
  static const List<List<String>> _dialerNumbers = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['*', '0', '#'],
  ];
  
  static const List<List<String>> _dialerLetters = [
    ['.', 'ABC', 'DEF'],
    ['GHI', 'JKL', 'MNO'],
    ['PQRS', 'TUV', 'WXYZ'],
    ['', '+', '.'],
  ];

  @override
  void initState() {
    super.initState();
    _initializeDTMFSounds();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  /// Initialize DTMF sounds for better performance
  Future<void> _initializeDTMFSounds() async {
    try {
      await DTMFAudioService.preloadSounds();
    } catch (e) {
      // Silent fail - DTMF will still work with fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SipService>(
      builder: (context, sipService, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final layout = _calculateLayout(constraints);
                return _buildDialerInterface(sipService, layout);
              },
            ),
          ),
        );
      },
    );
  }

  /// Calculate responsive layout dimensions
  _DialerLayout _calculateLayout(BoxConstraints constraints) {
    final screenHeight = constraints.maxHeight;
    final screenWidth = constraints.maxWidth;
    
    return _DialerLayout(
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      numberDisplayHeight: screenHeight * 0.15,
      dialPadHeight: screenHeight * 0.65,
      controlsHeight: screenHeight * 0.20,
      buttonSize: (screenWidth - 60) / 3.5,
    );
  }

  /// Build the main dialer interface
  Widget _buildDialerInterface(SipService sipService, _DialerLayout layout) {
    return Column(
      children: [
        _buildNumberDisplay(layout),
        _buildDialPad(layout),
        _buildControls(sipService, layout),
      ],
    );
  }

  /// Build number display area
  Widget _buildNumberDisplay(_DialerLayout layout) {
    return Container(
      height: layout.numberDisplayHeight,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: Text(
          _phoneController.text.isEmpty
              ? ''
              : _formatPhoneNumber(_phoneController.text),
          style: TextStyle(
            fontSize: _getResponsiveFontSize(layout.screenWidth),
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onBackground,
            letterSpacing: 1.0,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  /// Build dial pad
  Widget _buildDialPad(_DialerLayout layout) {
    return Expanded(
      child: Container(
        height: layout.dialPadHeight,
        padding: EdgeInsets.symmetric(horizontal: layout.screenWidth * 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _dialerNumbers.asMap().entries.map((entry) {
            final rowIndex = entry.key;
            final numbers = entry.value;
            final letters = _dialerLetters[rowIndex];
            return _buildDialerRow(numbers, letters, layout.buttonSize);
          }).toList(),
        ),
      ),
    );
  }

  /// Build dialer row
  Widget _buildDialerRow(List<String> numbers, List<String> letters, double buttonSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.asMap().entries.map((entry) {
        final index = entry.key;
        final number = entry.value;
        final letter = letters[index];
        return _buildDialerButton(number, letter, buttonSize);
      }).toList(),
    );
  }

  /// Build individual dialer button
  Widget _buildDialerButton(String number, String letters, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getDialerButtonColor(),
        shape: BoxShape.circle,
   
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
          onTap: () => _handleDialerTap(number),
          onLongPress: () => _handleDialerLongPress(number),
          child: _buildButtonContent(number, letters, size),
        ),
      ),
    );
  }

  /// Build button content (number and letters)
  Widget _buildButtonContent(String number, String letters, double size) {
    final numberFontSize = size * 0.4;
    final letterFontSize = size * 0.12;

    return Stack(
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
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.0,
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
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: size * 0.02,
                  height: 1.0,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Build controls area (call button and delete)
  Widget _buildControls(SipService sipService, _DialerLayout layout) {
    return Container(
      height: layout.controlsHeight,
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Expanded(child: SizedBox()),
          _buildCallButton(sipService, layout.buttonSize * 0.95),
          Expanded(
            child: _phoneController.text.isNotEmpty
                ? Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: _buildDeleteButton(layout.buttonSize * 0.6),
                    ),
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  /// Build call button
  Widget _buildCallButton(SipService sipService, double size) {
    final canCall =  
        sipService.status == SipConnectionStatus.connected;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: canCall ? const Color(0xFF34C759) : Colors.grey.shade400,
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

  /// Build delete button
  Widget _buildDeleteButton(double size) {
    return GestureDetector(
      onTap: _handleDeleteTap,
      onLongPress: _handleDeleteLongPress,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: Icon(
          Icons.backspace,
          color: AppThemes.getSecondaryTextColor(context),
          size: size * 0.55,
        ),
      ),
    );
  }

  /// Handle dialer button tap
  Future<void> _handleDialerTap(String number) async {
    await DTMFAudioService.playDTMF(number);
    _addNumberToDisplay(number);
    _sendDTMFToActiveCall(number);
  }

  /// Handle dialer button long press
  Future<void> _handleDialerLongPress(String number) async {
    await DTMFAudioService.playLongDTMF(number);
    _addNumberToDisplay(number);
    _sendDTMFToActiveCall(number);
  }

  /// Handle delete button tap
  Future<void> _handleDeleteTap() async {
    await DTMFAudioService.stopDTMF();
    if (_phoneController.text.isNotEmpty) {
      setState(() {
        _phoneController.text = _phoneController.text.substring(
          0,
          _phoneController.text.length - 1,
        );
      });
    }
  }

  /// Handle delete button long press
  Future<void> _handleDeleteLongPress() async {
    await DTMFAudioService.stopDTMF();
    setState(() {
      _phoneController.clear();
    });
  }

  /// Add number to display
  void _addNumberToDisplay(String number) {
    setState(() {
      _phoneController.text += number;
    });
  }

  /// Send DTMF to active call
  void _sendDTMFToActiveCall(String digit) {
    final sipService = Provider.of<SipService>(context, listen: false);
    if (sipService.callStatus == CallStatus.active) {
      sipService.sendDTMF(digit);
    }
  }

  /// Make a call
  Future<void> _makeCall(SipService sipService) async {
    final number = _phoneController.text.trim();
    if (number.isEmpty) return;

    final success = await sipService.makeCall(number);
    if (!success && mounted) {
      _showErrorSnackBar(sipService.errorMessage ?? 'Failed to make call');
    }
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF3B30),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Get dialer button color based on theme
  Color _getDialerButtonColor() {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFE5E5E5);
  }

  /// Get responsive font size for number display
  double _getResponsiveFontSize(double screenWidth) {
    if (screenWidth < 350) return 28;
    if (screenWidth < 400) return 32;
    return 38;
  }

  /// Format phone number for display
  String _formatPhoneNumber(String number) {
    if (number.length <= 3) {
      return number;
    } else if (number.length <= 6) {
      return '${number.substring(0, 3)}-${number.substring(3)}';
    } else if (number.length <= 10) {
      return '(${number.substring(0, 3)}) ${number.substring(3, 6)}-${number.substring(6)}';
    } else {
      final countryCode = number.substring(0, number.length - 10);
      final areaCode = number.substring(number.length - 10, number.length - 7);
      final prefix = number.substring(number.length - 7, number.length - 4);
      final lineNumber = number.substring(number.length - 4);
      return '+$countryCode ($areaCode) $prefix-$lineNumber';
    }
  }
}

/// Layout configuration for responsive design
class _DialerLayout {
  final double screenWidth;
  final double screenHeight;
  final double numberDisplayHeight;
  final double dialPadHeight;
  final double controlsHeight;
  final double buttonSize;

  const _DialerLayout({
    required this.screenWidth,
    required this.screenHeight,
    required this.numberDisplayHeight,
    required this.dialPadHeight,
    required this.controlsHeight,
    required this.buttonSize,
  });
}