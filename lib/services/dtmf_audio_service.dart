// lib/services/dtmf_audio_service.dart - UPDATED: Vibration only, no audio

import 'package:flutter/services.dart';

class DTMFAudioService {
  static bool _vibrationEnabled = true;

  // DTMF frequencies for reference (kept for documentation)
  static const Map<String, Map<String, int>> dtmfFrequencies = {
    '1': {'low': 697, 'high': 1209},
    '2': {'low': 697, 'high': 1336},
    '3': {'low': 697, 'high': 1477},
    '4': {'low': 770, 'high': 1209},
    '5': {'low': 770, 'high': 1336},
    '6': {'low': 770, 'high': 1477},
    '7': {'low': 852, 'high': 1209},
    '8': {'low': 852, 'high': 1336},
    '9': {'low': 852, 'high': 1477},
    '*': {'low': 941, 'high': 1209},
    '0': {'low': 941, 'high': 1336},
    '#': {'low': 941, 'high': 1477},
  };

  /// Play DTMF tone for a digit - vibration only
  static Future<void> playDTMF(String digit) async {
    if (!_vibrationEnabled || !dtmfFrequencies.containsKey(digit)) {
      HapticFeedback.lightImpact();
      return;
    }

    try {
      // Immediate haptic feedback
      HapticFeedback.lightImpact();

      // Generate alternative feedback
      await _generateFallbackTone(digit);
    } catch (e) {
      // Fallback to haptic only
      HapticFeedback.lightImpact();
    }
  }

  /// Enhanced fallback with better haptic patterns
  static Future<void> _generateFallbackTone(String digit) async {
    // Create realistic DTMF-like haptic patterns
    switch (digit) {
      case '1':
        HapticFeedback.lightImpact();
        await Future.delayed(const Duration(milliseconds: 30));
        HapticFeedback.lightImpact();
        break;
      case '2':
        HapticFeedback.lightImpact();
        await Future.delayed(const Duration(milliseconds: 20));
        HapticFeedback.lightImpact();
        await Future.delayed(const Duration(milliseconds: 20));
        HapticFeedback.lightImpact();
        break;
      case '3':
        HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 40));
        HapticFeedback.lightImpact();
        break;
      case '4':
        HapticFeedback.mediumImpact();
        break;
      case '5':
        HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 25));
        HapticFeedback.mediumImpact();
        break;
      case '6':
        HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 15));
        HapticFeedback.heavyImpact();
        break;
      case '7':
        HapticFeedback.heavyImpact();
        break;
      case '8':
        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 30));
        HapticFeedback.heavyImpact();
        break;
      case '9':
        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 20));
        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 20));
        HapticFeedback.heavyImpact();
        break;
      case '0':
        HapticFeedback.vibrate();
        await Future.delayed(const Duration(milliseconds: 50));
        HapticFeedback.mediumImpact();
        break;
      case '*':
        HapticFeedback.vibrate();
        await Future.delayed(const Duration(milliseconds: 25));
        HapticFeedback.vibrate();
        break;
      case '#':
        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 30));
        HapticFeedback.vibrate();
        break;
      default:
        HapticFeedback.lightImpact();
    }
  }

  /// Play longer DTMF for key hold - vibration only
  static Future<void> playLongDTMF(String digit) async {
    if (!_vibrationEnabled || !dtmfFrequencies.containsKey(digit)) {
      HapticFeedback.mediumImpact();
      return;
    }

    try {
      HapticFeedback.mediumImpact();
    } catch (e) {
      HapticFeedback.mediumImpact();
    }
  }

  /// Stop any playing DTMF (no-op since we're not playing audio)
  static Future<void> stopDTMF() async {
    // No audio to stop
    return;
  }

  /// Enable/disable vibration feedback
  static void setVibrationEnabled(bool enabled) {
    _vibrationEnabled = enabled;
  }

  /// Getters
  static bool get isVibrationEnabled => _vibrationEnabled;
  static bool get isSoundEnabled => false;
  static bool get isInitialized => true;

  /// Optional: Preload/prepare haptics (no-op but kept for compatibility)
  static Future<void> preloadSounds() async {
    // No sounds to preload
    return;
  }

  /// Cleanup (no-op since no audio resources to dispose)
  static Future<void> dispose() async {
    // No resources to dispose
    return;
  }

  /// Legacy method for compatibility
  static void setSoundEnabled(bool enabled) {
    // No-op since we don't have sound anymore
  }
}