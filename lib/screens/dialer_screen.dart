// lib/screens/dialer_screen.dart - UPDATED: Connection warnings moved to main app bar

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sip_service.dart';
import '../services/multi_account_manager.dart';
import '../services/dtmf_audio_service.dart';
import '../themes/app_themes.dart';

class DialerTab extends StatefulWidget {
  final SipService? sipService;
  
  const DialerTab({super.key, this.sipService});

  @override
  State<DialerTab> createState() => _DialerTabState();
}

class _DialerTabState extends State<DialerTab> {
  final TextEditingController _phoneController = TextEditingController();

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

  Future<void> _initializeDTMFSounds() async {
    try {
      await DTMFAudioService.preloadSounds();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MultiAccountManager>(
      builder: (context, accountManager, child) {
        final activeSipService = widget.sipService ?? accountManager.activeSipService;
        
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return _buildDialerInterface(activeSipService, constraints);
              },
            ),
          ),
        );
      },
    );
  }

  // UPDATED: Responsive layout calculation - removed warning widgets
  Widget _buildDialerInterface(SipService? sipService, BoxConstraints constraints) {
    final screenHeight = constraints.maxHeight;
    final screenWidth = constraints.maxWidth;
    
    // Calculate responsive sizes with more space available
    final numberDisplayHeight = screenHeight * 0.15; // Increased back since no warnings
    final controlsHeight = screenHeight * 0.18; // Increased slightly
    final dialPadHeight = screenHeight - numberDisplayHeight - controlsHeight - 32; // 32 for spacing
    final buttonSize = (screenWidth - 80) / 3.8; // More conservative sizing

    return Column(
      children: [
        // Number display
        SizedBox(
          height: numberDisplayHeight,
          child: _buildNumberDisplay(),
        ),
        
        const SizedBox(height: 16),
        
        // Dial pad - use remaining space
        Flexible(
          child: _buildDialPad(dialPadHeight, buttonSize, screenWidth),
        ),
        
        const SizedBox(height: 16),
        
        // Controls
        SizedBox(
          height: controlsHeight,
          child: _buildControls(sipService, buttonSize),
        ),
      ],
    );
  }

  Widget _buildNumberDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Text(
            _phoneController.text.isEmpty
                ? ''
                : _formatPhoneNumber(_phoneController.text),
            style: TextStyle(
              fontSize: 40, // Increased back to original size
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onBackground,
              letterSpacing: 1.0,
            ),
            maxLines: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildDialPad(double height, double buttonSize, double screenWidth) {
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _dialerNumbers.asMap().entries.map((entry) {
          final rowIndex = entry.key;
          final numbers = entry.value;
          final letters = _dialerLetters[rowIndex];
          return _buildDialerRow(numbers, letters, buttonSize);
        }).toList(),
      ),
    );
  }

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

  Widget _buildButtonContent(String number, String letters, double size) {
    final numberFontSize = size * 0.38;
    final letterFontSize = size * 0.11;

    return Container(
      width: size,
      height: size,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Top spacing for better centering
          if (letters.isNotEmpty && letters != '.') 
            SizedBox(height: size * 0.12)
          else 
            SizedBox(height: size * 0.25),
          
          // Number - perfectly centered
          Text(
            number,
            style: TextStyle(
              fontSize: numberFontSize,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.0,
            ),
            textAlign: TextAlign.center,
          ),
          
          // Letters below number (if exists)
          if (letters.isNotEmpty && letters != '.') ...[
            SizedBox(height: size * 0.02),
            Text(
              letters,
              style: TextStyle(
                fontSize: letterFontSize,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: size * 0.01,
                height: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: size * 0.12),
          ] else
            SizedBox(height: size * 0.25),
        ],
      ),
    );
  }

  Widget _buildControls(SipService? sipService, double buttonSize) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Expanded(child: SizedBox()),
          _buildCallButton(sipService, buttonSize * 0.90),
          Expanded(
            child: _phoneController.text.isNotEmpty
                ? Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: _buildDeleteButton(buttonSize * 0.55),
                    ),
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildCallButton(SipService? sipService, double size) {
    final canCall = sipService?.status == SipConnectionStatus.connected;
    final hasNumber = _phoneController.text.trim().isNotEmpty;
    final isEnabled = canCall && hasNumber;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF34C759),
        shape: BoxShape.circle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          onTap: isEnabled ? () => _makeCall(sipService!) : null,
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

  Future<void> _handleDialerTap(String number) async {
    await DTMFAudioService.playDTMF(number);
    _addNumberToDisplay(number);
    _sendDTMFToActiveCall(number);
  }

  Future<void> _handleDialerLongPress(String number) async {
    await DTMFAudioService.playLongDTMF(number);
    _addNumberToDisplay(number);
    _sendDTMFToActiveCall(number);
  }

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

  Future<void> _handleDeleteLongPress() async {
    await DTMFAudioService.stopDTMF();
    setState(() {
      _phoneController.clear();
    });
  }

  void _addNumberToDisplay(String number) {
    setState(() {
      _phoneController.text += number;
    });
  }

  void _sendDTMFToActiveCall(String digit) {
    final accountManager = Provider.of<MultiAccountManager>(context, listen: false);
    
    for (final sipService in accountManager.allSipServices.values) {
      if (sipService.callStatus == CallStatus.active) {
        sipService.sendDTMF(digit);
        break;
      }
    }
  }

  Future<void> _makeCall(SipService sipService) async {
    final number = _phoneController.text.trim();
    if (number.isEmpty) return;

    if (sipService.status != SipConnectionStatus.connected) {
      _showErrorDialog('Not connected to server. Please check your connection.');
      return;
    }

    if (sipService.callStatus != CallStatus.idle) {
      _showErrorDialog('Another call is already in progress.');
      return;
    }

    print('📞 [DialerTab] Attempting to make call to: $number');
    print('📊 [DialerTab] SIP Status: ${sipService.status}');
    print('📊 [DialerTab] Call Status: ${sipService.callStatus}');

    try {
      final success = await sipService.makeCall(number);
      if (!success && mounted) {
        final errorMsg = sipService.errorMessage ?? 'Failed to make call';
        _showErrorDialog(errorMsg);
      } else {
        print('✅ [DialerTab] Call initiated successfully');
      }
    } catch (e) {
      print('❌ [DialerTab] Exception making call: $e');
      if (mounted) {
        _showErrorDialog('Failed to make call: $e');
      }
    }
  }

  Future<void> _showErrorDialog(String message) async {
    await showOkAlertDialog(
      context: context,
      title: 'Call Failed',
      message: message,
    );
  }

  Color _getDialerButtonColor() {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFE5E5E5);
  }

  String _formatPhoneNumber(String number) {
    if (number.length <= 3) {
      return number;
    } else if (number.length <= 6) {
      return '${number.substring(0, 3)} ${number.substring(3)}';
    } else if (number.length <= 10) {
      return '${number.substring(0, 3)} ${number.substring(3, 6)} ${number.substring(6)}';
    } else {
      final countryCode = number.substring(0, number.length - 10);
      final areaCode = number.substring(number.length - 10, number.length - 7);
      final prefix = number.substring(number.length - 7, number.length - 4);
      final lineNumber = number.substring(number.length - 4);
      return '$countryCode $areaCode $prefix $lineNumber';
    }
  }
}