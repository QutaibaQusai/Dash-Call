import 'package:adaptive_dialog/adaptive_dialog.dart';
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

  Widget _buildDialerInterface(SipService sipService, _DialerLayout layout) {
    return Column(
      children: [
        _buildNumberDisplay(layout),
        _buildDialPad(layout),
        _buildControls(sipService, layout),
      ],
    );
  }

  Widget _buildNumberDisplay(_DialerLayout layout) {
    return Container(
      height: layout.numberDisplayHeight,
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
              fontSize: 40, // starting size, will scale down
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
    final numberFontSize = size * 0.4;
    final letterFontSize = size * 0.12;

    return Stack(
      children: [
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
              ),
            ),
          ),
        ),
// Letters
if (letters.isNotEmpty && letters != '.')
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

  Widget _buildCallButton(SipService sipService, double size) {
    final canCall = sipService.status == SipConnectionStatus.connected;

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF34C759),
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
    final sipService = Provider.of<SipService>(context, listen: false);
    if (sipService.callStatus == CallStatus.active) {
      sipService.sendDTMF(digit);
    }
  }

  Future<void> _makeCall(SipService sipService) async {
    final number = _phoneController.text.trim();
    if (number.isEmpty) return;

    final success = await sipService.makeCall(number);
    if (!success && mounted) {
      _showErrorDialog(sipService.errorMessage ?? 'Failed to make call');
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
