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
  late Animation<double> _pulseAnimation;

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
  }

  @override
  void dispose() {
    _pulseController.dispose();
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

  void _endCall() {
    HapticFeedback.heavyImpact();
    widget.sipService.hangupCall();
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
      backgroundColor: const Color(0xFF000000),
      body: Container(
        width: double.infinity, // FIXED: Ensure full width
        height: double.infinity, // FIXED: Ensure full height
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1C1C1E), Color(0xFF000000)],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Status bar spacing
              const SizedBox(height: 30),

              // Call info section
              Expanded(child: _buildCallInfoSection()),

              // Controls section
              _buildControlsSection(),

              // Bottom spacing
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallInfoSection() {
    return Container(
      width: double.infinity, // FIXED: Ensure full width
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          const SizedBox(height: 40),

          // Contact name/number
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
            ), // FIXED: Add padding
            child: Text(
              widget.sipService.callNumber ?? 'Unknown',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w300,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 2, // FIXED: Allow multiple lines for long numbers
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 12),

          // Call status
          Text(
            _getCallStatusText(),
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF8E8E93),
              fontWeight: FontWeight.w400,
            ),
          ),

          // Call duration (for active calls)
          if (widget.sipService.callStartTime != null &&
              widget.sipService.callStatus == CallStatus.active)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: StreamBuilder(
                stream: Stream.periodic(const Duration(seconds: 1)),
                builder: (context, snapshot) {
                  final duration = DateTime.now().difference(
                    widget.sipService.callStartTime!,
                  );
                  return Text(
                    _formatDuration(duration),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF8E8E93),
                      fontWeight: FontWeight.w400,
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
    if (widget.sipService.callStatus == CallStatus.incoming) {
      return _buildIncomingCallControls();
    } else if (widget.sipService.callStatus == CallStatus.calling) {
      return _buildOutgoingCallControls();
    } else {
      return _buildActiveCallControls();
    }
  }

  Widget _buildIncomingCallControls() {
    return Container(
      width: double.infinity, // FIXED: Ensure full width
      padding: const EdgeInsets.symmetric(horizontal: 80),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Decline button
          _buildCircularButton(
            icon: CupertinoIcons.phone_down_fill,
            backgroundColor: const Color(0xFFFF3B30),
            onPressed: () => widget.sipService.rejectCall(),
            size: 75,
          ),

          // Accept button
          _buildCircularButton(
            icon: CupertinoIcons.phone_fill,
            backgroundColor: const Color(0xFF34C759),
            onPressed: () => widget.sipService.answerCall(),
            size: 75,
          ),
        ],
      ),
    );
  }

  Widget _buildOutgoingCallControls() {
    return Container(
      width: double.infinity, // FIXED: Ensure full width
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Loading indicator
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8E8E93)),
              strokeWidth: 2,
            ),
          ),

          const SizedBox(height: 50),

          // End call button - centered
          Center(
            child: _buildCircularButton(
              icon: CupertinoIcons.phone_down_fill,
              backgroundColor: const Color(0xFFFF3B30),
              onPressed: _endCall,
              size: 75,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCallControls() {
    return Container(
      width: double.infinity, // FIXED: Ensure full width
      child: Column(
        children: [
          // Control buttons row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Mute button
                _buildControlButton(
                  icon:
                      widget.sipService.isMuted
                          ? CupertinoIcons.mic_slash_fill
                          : CupertinoIcons.mic_fill,
                  label: 'mute',
                  isActive: widget.sipService.isMuted,
                  onPressed: _toggleMute,
                ),

                // Hold button
                _buildControlButton(
                  icon: CupertinoIcons.pause_fill,
                  label: 'hold',
                  isActive: widget.sipService.callStatus == CallStatus.held,
                  onPressed: _toggleHold,
                ),

                // Speaker button
                _buildControlButton(
                  icon: CupertinoIcons.speaker_3_fill,
                  label: 'speaker',
                  isActive: widget.sipService.isSpeakerOn,
                  onPressed: _toggleSpeaker,
                ),
              ],
            ),
          ),

          const SizedBox(height: 70),

          // End call button - centered
          Center(
            child: _buildCircularButton(
              icon: CupertinoIcons.phone_down_fill,
              backgroundColor: const Color(0xFFFF3B30),
              onPressed: _endCall,
              size: 75,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.white : const Color(0xFF2C2C2E),
            border: Border.all(
              color: isActive ? Colors.white : const Color(0xFF3A3A3C),
              width: 1,
            ),
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
              borderRadius: BorderRadius.circular(34),
              onTap: onPressed,
              child: Icon(
                icon,
                color: isActive ? Colors.black : Colors.white,
                size: 28,
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

  Widget _buildCircularButton({
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
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: onPressed,
          child: Icon(icon, color: Colors.white, size: size * 0.35),
        ),
      ),
    );
  }
}
