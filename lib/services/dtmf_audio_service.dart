// lib/services/dtmf_audio_service.dart

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class DTMFAudioService {
  static AudioPlayer? _audioPlayer;
  static bool _isInitialized = false;
  static bool _soundEnabled = true;
  static bool _isInitializing = false;

  // DTMF frequencies for reference
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

  /// Auto-initialize when needed (lazy initialization)
  static Future<void> _ensureInitialized() async {
    if (_isInitialized || _isInitializing) return;

    _isInitializing = true;

    try {
      _audioPlayer = AudioPlayer();

      // Configure for optimal DTMF playback
      await _audioPlayer!.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: [AVAudioSessionOptions.mixWithOthers],
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.assistanceSonification,
            audioFocus: AndroidAudioFocus.none,
          ),
        ),
      );

      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
    } finally {
      _isInitializing = false;
    }
  }

  /// Play DTMF tone for a digit - auto-initializes if needed
  static Future<void> playDTMF(String digit) async {
    if (!_soundEnabled || !dtmfFrequencies.containsKey(digit)) {
      HapticFeedback.lightImpact();
      return;
    }

    // Auto-initialize if needed
    await _ensureInitialized();

    if (!_isInitialized || _audioPlayer == null) {
      HapticFeedback.lightImpact();
      return;
    }

    try {
      // Immediate haptic feedback
      HapticFeedback.lightImpact();

      // Stop any playing sound
      await _audioPlayer!.stop();

      // Play DTMF audio
      await _playAudioFile(digit);
    } catch (e) {
      // Fallback to haptic only
      HapticFeedback.lightImpact();
    }
  }

  /// Play audio file with proper mapping for special characters
  static Future<void> _playAudioFile(String digit) async {
    try {
      // Map special characters to valid file names
      String fileName = digit;
      if (digit == '*') fileName = 'star';
      if (digit == '#') fileName = 'hash';

      final source = AssetSource('sounds/dtmf/dtmf_$fileName.wav');

      await _audioPlayer!.play(
        source,
        volume: 0.6,
        mode: PlayerMode.lowLatency,
      );
    } catch (e) {
      // Generate alternative feedback
      await _generateFallbackTone(digit);
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

  /// Play longer DTMF for key hold
  static Future<void> playLongDTMF(String digit) async {
    await _ensureInitialized();

    if (!_isInitialized || _audioPlayer == null) {
      HapticFeedback.mediumImpact();
      return;
    }

    try {
      HapticFeedback.mediumImpact();
      await _audioPlayer!.stop();

      String fileName = digit;
      if (digit == '*') fileName = 'star';
      if (digit == '#') fileName = 'hash';

      // Try long version, fallback to regular
      try {
        final source = AssetSource('sounds/dtmf/dtmf_${fileName}_long.wav');
        await _audioPlayer!.play(source, volume: 0.7);
      } catch (e) {
        final source = AssetSource('sounds/dtmf/dtmf_$fileName.wav');
        await _audioPlayer!.play(source, volume: 0.7);
      }
    } catch (e) {
      HapticFeedback.mediumImpact();
    }
  }

  /// Stop any playing DTMF
  static Future<void> stopDTMF() async {
    if (_audioPlayer != null) {
      try {
        await _audioPlayer!.stop();
      } catch (e) {
        // Silent fail
      }
    }
  }

  /// Enable/disable sounds
  static void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  /// Getters
  static bool get isSoundEnabled => _soundEnabled;
  static bool get isInitialized => _isInitialized;

  /// Optional: Preload sounds for better performance
  static Future<void> preloadSounds() async {
    await _ensureInitialized();

    if (!_isInitialized) return;

    for (String digit in dtmfFrequencies.keys) {
      try {
        String fileName = digit;
        if (digit == '*') fileName = 'star';
        if (digit == '#') fileName = 'hash';

        final source = AssetSource('sounds/dtmf/dtmf_$fileName.wav');
        // Just create a temporary player to preload
        final tempPlayer = AudioPlayer();
        await tempPlayer.setSource(source);
        await tempPlayer.dispose();
      } catch (e) {
        // Ignore preload errors
      }
    }
  }

  /// Cleanup (call this when app is disposed)
  static Future<void> dispose() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
        await _audioPlayer!.dispose();
        _audioPlayer = null;
      }
      _isInitialized = false;
      _isInitializing = false;
    } catch (e) {
      // Silent fail
    }
  }
}
