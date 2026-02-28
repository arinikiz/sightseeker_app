import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

/// Playback state for TTS audio.
enum AudioPlaybackState {
  idle,
  playing,
  paused,
  stopped,
}

/// Controller for playing TTS audio. Currently stubbed: no real audio output.
///
/// When adding real playback (e.g. just_audio):
/// - Use a package that can play from bytes or file (e.g. just_audio's
///   AudioSource.uri with a temp file, or audioplayers setSource(byteSource)).
/// - In [play], feed [bytes] to the player and listen to position/duration.
/// - [pause]/[stop] call the player's pause/stop; [resume] calls play.
/// - Notify listeners on state and position changes.
class AudioPlayerController extends ChangeNotifier {
  AudioPlaybackState _state = AudioPlaybackState.idle;
  Uint8List? _currentBytes;
  Timer? _simulationTimer;

  AudioPlaybackState get state => _state;

  /// Stub: "play" by simulating a duration (no real audio). Replace with
  /// actual player when integrating a package (e.g. just_audio).
  void play(Uint8List bytes) {
    _currentBytes = bytes;
    _state = AudioPlaybackState.playing;
    notifyListeners();

    _simulationTimer?.cancel();
    // Simulate ~3s playback; replace with real duration from player when available.
    const simulatedDuration = Duration(seconds: 3);
    _simulationTimer = Timer(simulatedDuration, () {
      _state = AudioPlaybackState.idle;
      _simulationTimer = null;
      notifyListeners();
    });
  }

  /// Pause playback. Stub: just stop the timer and set paused.
  void pause() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    _state = AudioPlaybackState.paused;
    notifyListeners();
  }

  /// Resume from paused. Stub: go back to playing with remaining time.
  void resume() {
    if (_state != AudioPlaybackState.paused || _currentBytes == null) return;
    _state = AudioPlaybackState.playing;
    notifyListeners();
    const simulatedDuration = Duration(seconds: 3);
    _simulationTimer = Timer(simulatedDuration, () {
      _state = AudioPlaybackState.idle;
      _simulationTimer = null;
      notifyListeners();
    });
  }

  /// Stop and reset to idle.
  void stop() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    _state = AudioPlaybackState.idle;
    _currentBytes = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }
}
