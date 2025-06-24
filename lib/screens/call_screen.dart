// lib/screens/call_screen.dart - Exact iOS Native UI

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/sip_service.dart';

class CallScreen extends StatefulWidget {
  final SipService sipService;

  const CallScreen({super.key, required this.sipService});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _showKeypad = false;

  @override
  void initState() {
    super.initState();

    // Pulse animation for active call indicator
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Slide animation for controls
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _slideController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _toggleMute() {
    HapticFeedback.lightImpact();
    widget.sipService.toggleMute();
  }

  void _toggleSpeaker() {
    HapticFeedback.lightImpact();
    widget.sipService.toggleSpeaker();
  }

  void _toggleHold() {
    HapticFeedback.lightImpact();
    if (widget.sipService.callStatus == CallStatus.held) {
      widget.sipService.resumeCall();
    } else {
      widget.sipService.holdCall();
    }
  }

  void _toggleKeypad() {
    HapticFeedback.lightImpact();
    setState(() {
      _showKeypad = !_showKeypad;
    });
  }

  void _endCall() {
    HapticFeedback.heavyImpact();
    widget.sipService.hangupCall();
  }

  void _answerCall() {
    HapticFeedback.lightImpact();
    widget.sipService.answerCall();
  }

  void _rejectCall() {
    HapticFeedback.heavyImpact();
    widget.sipService.rejectCall();
  }

  String _getCallStatusText() {
    switch (widget.sipService.callStatus) {
      case CallStatus.calling:
        return 'Calling...';
      case CallStatus.incoming:
        return 'Incoming call';
      case CallStatus.active:
        return 'Connected';
      case CallStatus.held:
        return 'On hold';
      default:
        return 'Call';
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      final hours = twoDigits(duration.inHours);
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              Color(0xFF1C1C1E),
              Color(0xFF000000),
            ],
          ),
        ),
        child: SafeArea(
          child: _showKeypad ? _buildKeypadView() : _buildCallView(),
        ),
      ),
    );
  }

  // Main call view - exactly like iOS native
  Widget _buildCallView() {
    return Column(
      children: [
        // Top section with call info - takes up most space
        Expanded(
          flex: 3,
          child: _buildCallInfoSection(),
        ),

        // Controls section - bottom part
        Container(
          height: 435,
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildControlsSection(),
          ),
        ),
      ],
    );
  }

  Widget _buildCallInfoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          // Contact name/number - large and prominent
          Text(
            widget.sipService.callNumber ?? 'Unknown',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w300,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 12),

          // Call duration - above status
          if (widget.sipService.callStartTime != null &&
              widget.sipService.callStatus == CallStatus.active)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: StreamBuilder(
                stream: Stream.periodic(const Duration(seconds: 1)),
                builder: (context, snapshot) {
                  final callStartTime = widget.sipService.callStartTime;
                  if (callStartTime == null) {
                    return const SizedBox.shrink();
                  }

                  final duration = DateTime.now().difference(callStartTime);
                  return Text(
                    _formatDuration(duration),
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF8E8E93),
                      fontWeight: FontWeight.w400,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  );
                },
              ),
            ),

          // Call status
          Text(
            _getCallStatusText(),
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF8E8E93),
              fontWeight: FontWeight.w400,
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildControlsSection() {
    switch (widget.sipService.callStatus) {
      case CallStatus.incoming:
        return _buildIncomingCallControls();
      case CallStatus.calling:
        return _buildOutgoingCallControls();
      case CallStatus.active:
      case CallStatus.held:
        return _buildActiveCallControls();
      default:
        return _buildActiveCallControls();
    }
  }

  Widget _buildIncomingCallControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Additional options for incoming call
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSmallControlButton(
                icon: CupertinoIcons.chat_bubble_fill,
                label: 'Message',
                onPressed: () {},
              ),
              _buildSmallControlButton(
                icon: CupertinoIcons.person_add_solid,
                label: 'Remind Me',
                onPressed: () {},
              ),
            ],
          ),

          const SizedBox(height: 40),

          // Answer/Decline buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAnswerButton(
                icon: CupertinoIcons.phone_down_fill,
                backgroundColor: const Color(0xFFFF3B30),
                onPressed: _rejectCall,
                size: 80,
              ),
              _buildAnswerButton(
                icon: CupertinoIcons.phone_fill,
                backgroundColor: const Color(0xFF34C759),
                onPressed: _answerCall,
                size: 80,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutgoingCallControls() {
    return _buildActiveCallControls();
  }

  // iOS native call controls layout - Updated with Hold centered
  Widget _buildActiveCallControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: Column(
        children: [
          // First row - Mute, Speaker, Keypad
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: widget.sipService.isMuted
                    ? CupertinoIcons.mic_slash_fill
                    : CupertinoIcons.mic_fill,
                label: 'Mute',
                isActive: widget.sipService.isMuted,
                onPressed: _toggleMute,
              ),
              _buildControlButton(
                icon: widget.sipService.isSpeakerOn
                    ? CupertinoIcons.speaker_3_fill
                    : CupertinoIcons.speaker_1_fill,
                label: 'Speaker',
                isActive: widget.sipService.isSpeakerOn,
                onPressed: _toggleSpeaker,
              ),
              _buildControlButton(
                icon: Icons.dialpad,
                label: 'Keypad',
                isActive: _showKeypad,
                onPressed: _toggleKeypad,
              ),
            ],
          ),

          const SizedBox(height: 40),

          // Second row - Hold button centered
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlButton(
                icon: widget.sipService.callStatus == CallStatus.held
                    ? CupertinoIcons.play_fill
                    : CupertinoIcons.pause_fill,
                label: widget.sipService.callStatus == CallStatus.held ? 'Resume' : 'Hold',
                isActive: widget.sipService.callStatus == CallStatus.held,
                onPressed: _toggleHold,
              ),
            ],
          ),

          const SizedBox(height: 40),

          // Third row - End Call button centered
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAnswerButton(
                icon: CupertinoIcons.phone_down_fill,
                backgroundColor: const Color(0xFFFF3B30),
                onPressed: _endCall,
                size: 80,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // iOS native keypad view
  Widget _buildKeypadView() {
    return Column(
      children: [
        // Top section with number and timer
        Container(
          height: 210,
          child: _buildCallInfoSection(),
        ),

        // Keypad grid
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Row 1
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildKeypadButton('1', ''),
                    _buildKeypadButton('2', 'ABC'),
                    _buildKeypadButton('3', 'DEF'),
                  ],
                ),
                // Row 2
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildKeypadButton('4', 'GHI'),
                    _buildKeypadButton('5', 'JKL'),
                    _buildKeypadButton('6', 'MNO'),
                  ],
                ),
                // Row 3
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildKeypadButton('7', 'PQRS'),
                    _buildKeypadButton('8', 'TUV'),
                    _buildKeypadButton('9', 'WXYZ'),
                  ],
                ),
                // Row 4
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildKeypadButton('*', ''),
                    _buildKeypadButton('0', '+'),
                    _buildKeypadButton('#', ''),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Bottom section - End call and Hide Keypad
    Container(
  height: 140,
  width: double.infinity,
  child: Stack(
    children: [
      // "Hide Keypad" on the right
      Positioned(
        right: 24,
        top: 0,
        bottom: 0,
        child: Center(
          child: GestureDetector(
            onTap: _toggleKeypad,
            child: const Text(
              'Hide Keypad',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),

      // End Call button centered
      Align(
        alignment: Alignment.center,
        child: _buildAnswerButton(
          icon: CupertinoIcons.phone_down_fill,
          backgroundColor: const Color(0xFFFF3B30),
          onPressed: _endCall,
          size: 80,
        ),
      ),
    ],
  ),
),

        const SizedBox(height: 30),
      ],
    );
  }

  // iOS native keypad button
  Widget _buildKeypadButton(String number, String letters) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.sipService.sendDTMF(number);
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: const BoxDecoration(
          color: Color(0xFF2C2C2E),
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              number,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w300,
                color: Colors.white,
                height: 1.0,
              ),
            ),
            if (letters.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                letters,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                  letterSpacing: 2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // iOS native control button
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.white : const Color(0xFF2C2C2E),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(40),
              onTap: onPressed,
              child: Icon(
                icon,
                color: isActive ? Colors.black : Colors.white,
                size: 32,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isActive ? Colors.white : const Color(0xFF8E8E93),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2C2C2E),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: onPressed,
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF8E8E93),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerButton({
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onPressed,
    required double size,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: onPressed,
          child: Icon(
            icon,
            color: Colors.white,
            size: size * 0.4,
          ),
        ),
      ),
    );
  }
}