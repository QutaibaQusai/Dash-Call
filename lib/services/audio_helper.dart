// Create this file: lib/services/audio_helper.dart

import 'package:flutter_webrtc/flutter_webrtc.dart';

class AudioHelper {
  static bool _isSpeakerOn = false;
  
  /// Set speaker phone on/off using the basic WebRTC API
  static Future<bool> setSpeakerOn(bool enable) async {
    try {
      print('🔊 [AudioHelper] Setting speaker: $enable');
      
      // Use the basic setSpeakerphoneOn method that's available
      await Helper.setSpeakerphoneOn(enable);
      
      _isSpeakerOn = enable;
      print('✅ [AudioHelper] Speaker set to: $enable');
      return true;
      
    } catch (e) {
      print('❌ [AudioHelper] Failed to set speaker: $e');
      return false;
    }
  }
  
  /// Initialize call audio (start with earpiece)
  static Future<void> initializeCallAudio() async {
    try {
      print('📞 [AudioHelper] Initializing call audio...');
      
      // Always start calls with earpiece for better UX
      await setSpeakerOn(false);
      
      print('✅ [AudioHelper] Call audio initialized with earpiece');
    } catch (e) {
      print('❌ [AudioHelper] Failed to initialize call audio: $e');
    }
  }
  
  /// Reset audio to default state
  static Future<void> resetAudio() async {
    try {
      print('🔄 [AudioHelper] Resetting audio to default...');
      
      await setSpeakerOn(false);
      _isSpeakerOn = false;
      
      print('✅ [AudioHelper] Audio reset completed');
    } catch (e) {
      print('❌ [AudioHelper] Failed to reset audio: $e');
    }
  }
  
  /// Get current speaker state
  static bool get isSpeakerOn => _isSpeakerOn;
  
  /// Toggle speaker
  static Future<bool> toggleSpeaker() async {
    return await setSpeakerOn(!_isSpeakerOn);
  }
  
  /// Initialize audio system (simplified)
  static Future<void> initialize() async {
    try {
      print('🎧 [AudioHelper] Initializing audio system...');
      
      // Just ensure speaker is off initially
      await setSpeakerOn(false);
      
      print('✅ [AudioHelper] Audio system initialized');
    } catch (e) {
      print('❌ [AudioHelper] Failed to initialize audio: $e');
    }
  }
}