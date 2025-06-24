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

  void _showKeypad() {
    HapticFeedback.lightImpact();
    // Handle keypad display
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
          child: Column(
            children: [
              // Top section with call info
              Expanded(
                child: _buildCallInfoSection(),
              ),

              // Controls section - Fixed height to prevent overflow
              Container(
                height: MediaQuery.of(context).size.height * 0.4,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildControlsSection(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallInfoSection() {
    final size = MediaQuery.of(context).size.height/6;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          
                     SizedBox(height: size),


    

          // Contact name/number
          Text(
            widget.sipService.callNumber ?? 'Unknown',
            style: const TextStyle(
              fontSize: 50,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 8),

          // Call status with animation for active calls
          widget.sipService.callStatus == CallStatus.active
              ? AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getCallStatusText(),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
              : Text(
                  _getCallStatusText(),
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF8E8E93),
                    fontWeight: FontWeight.w400,
                  ),
                ),

          // Call duration
          if (widget.sipService.callStartTime != null &&
              widget.sipService.callStatus == CallStatus.active)
            Padding(
              padding: const EdgeInsets.only(top: 12),
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
                      fontSize: 24,
                      color: Colors.white70,
                      fontWeight: FontWeight.w300,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  );
                },
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const SizedBox(height: 20),
        
        // Additional options for incoming call
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSmallControlButton(
              icon: CupertinoIcons.chat_bubble_fill,
              label: 'Message',
              onPressed: () {
                // Handle message
              },
            ),
            _buildSmallControlButton(
              icon: CupertinoIcons.person_add_solid,
              label: 'Add to contacts',
              onPressed: () {
                // Handle add contact
              },
            ),
          ],
        ),

        // Answer/Decline buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAnswerButton(
              icon: CupertinoIcons.phone_down_fill,
              backgroundColor: const Color(0xFFFF3B30),
              onPressed: _rejectCall,
              size: 70,
            ),
            _buildAnswerButton(
              icon: CupertinoIcons.phone_fill,
              backgroundColor: const Color(0xFF34C759),
              onPressed: _answerCall,
              size: 70,
            ),
          ],
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildOutgoingCallControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const SizedBox(height: 20),
          
          // First row - 3 buttons with only speaker enabled
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: widget.sipService.isMuted
                    ? CupertinoIcons.mic_slash_fill
                    : CupertinoIcons.mic_fill,
                label: 'Mute',
                isActive: widget.sipService.isMuted,
                isEnabled: false, // Disabled when calling
                onPressed: _toggleMute,
              ),
              _buildControlButton(
                icon: Icons.dialpad,
                label: 'Keypad',
                isActive: false,
                isEnabled: false, // Disabled when calling
                onPressed: _showKeypad,
              ),
              _buildControlButton(
                icon: CupertinoIcons.speaker_3_fill,
                label: 'Speaker',
                isActive: widget.sipService.isSpeakerOn,
                isEnabled: true, // Only speaker is enabled when calling
                onPressed: _toggleSpeaker,
              ),
            ],
          ),

          // Second row - Hold button disabled
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlButton(
                icon: CupertinoIcons.pause_fill,
                label: 'Hold',
                isActive: false,
                isEnabled: false, // Disabled when calling
                onPressed: _toggleHold,
              ),
            ],
          ),

          // End call button
          _buildAnswerButton(
            icon: CupertinoIcons.phone_down_fill,
            backgroundColor: const Color(0xFFFF3B30),
            onPressed: _endCall,
            size: 70,
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildActiveCallControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const SizedBox(height: 20),
          
          // First row of controls - all enabled when connected
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: widget.sipService.isMuted
                    ? CupertinoIcons.mic_slash_fill
                    : CupertinoIcons.mic_fill,
                label: 'Mute',
                isActive: widget.sipService.isMuted,
                isEnabled: true, // Enabled when connected
                onPressed: _toggleMute,
              ),
              _buildControlButton(
                icon: Icons.dialpad,
                label: 'Keypad',
                isActive: false,
                isEnabled: true, // Enabled when connected
                onPressed: _showKeypad,
              ),
              _buildControlButton(
                icon: CupertinoIcons.speaker_3_fill,
                label: 'Speaker',
                isActive: widget.sipService.isSpeakerOn,
                isEnabled: true, // Enabled when connected
                onPressed: _toggleSpeaker,
              ),
            ],
          ),

          // Second row - Hold button enabled when connected
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlButton(
                icon: widget.sipService.callStatus == CallStatus.held
                    ? CupertinoIcons.play_fill
                    : CupertinoIcons.pause_fill,
                label: widget.sipService.callStatus == CallStatus.held ? 'Resume' : 'Hold',
                isActive: widget.sipService.callStatus == CallStatus.held,
                isEnabled: true, // Enabled when connected
                onPressed: _toggleHold,
              ),
            ],
          ),

          // End call button
          _buildAnswerButton(
            icon: CupertinoIcons.phone_down_fill,
            backgroundColor: const Color(0xFFFF3B30),
            onPressed: _endCall,
            size: 70,
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

Widget _buildControlButton({
  required IconData icon,
  required String label,
  required bool isActive,
  required bool isEnabled,
  required VoidCallback onPressed,
}) {
  const double size = 70; // Same as "End Call" button

  final Color backgroundColor = isActive
      ? Colors.white
      : isEnabled
          ? const Color(0xFF2C2C2E)
          : const Color(0xFF1C1C1E);

  final Color iconColor = isActive
      ? Colors.black
      : isEnabled
          ? Colors.white
          : Colors.white.withOpacity(0.3);

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
              splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
            borderRadius: BorderRadius.circular(size / 2),
            onTap: isEnabled ? onPressed : null,
            child: Icon(
              icon,
              color: iconColor,
              size: size * 0.35, 
            ),
          ),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: isActive
              ? Colors.white
              : isEnabled
                  ? const Color(0xFF8E8E93)
                  : const Color(0xFF8E8E93).withOpacity(0.5),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2C2C2E),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              onTap: onPressed,
              child: Icon(
                icon,
                color: Colors.white,
                size: 22,
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
            blurRadius: 25,
            spreadRadius: 3,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
            size: size * 0.35,
          ),
        ),
      ),
    );
  }
}