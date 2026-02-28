import 'package:flutter/foundation.dart';

import '../services/tts/audio_player_controller.dart';
import '../services/tts/mock_tts_service.dart';
import '../services/tts/tts_service.dart';

/// TTS UI state for the listen button.
enum TtsState {
  idle,
  loading,
  playing,
  paused,
  error,
}

/// Controller for the listen (TTS) flow: synthesize then play.
/// Handles idle → loading → playing ↔ paused and error; ignores rapid taps while loading.
class TtsController extends ChangeNotifier {
  TtsController({
    required TtsService ttsService,
    AudioPlayerController? audioPlayer,
  })  : _ttsService = ttsService,
        _audioPlayer = audioPlayer ?? AudioPlayerController() {
    _audioPlayer.addListener(_onPlayerStateChanged);
  }

  final TtsService _ttsService;
  final AudioPlayerController _audioPlayer;

  TtsState _state = TtsState.idle;
  String? _errorMessage;

  TtsState get state => _state;
  String? get errorMessage => _errorMessage;

  /// TODO: Load from secure storage or env (e.g. flutter_dotenv). Do NOT hardcode.
  static String get _apiKey => const String.fromEnvironment(
        'ELEVENLABS_API_KEY',
        defaultValue: '',
      );

  /// TODO: ElevenLabs voice ID (e.g. from app config or constants).
  static const String _defaultVoiceId = 'EXAVITQu4vr4xnSDxMaL';

  /// TODO: ElevenLabs model ID; optional, API has default.
  static const String? _defaultModelId = null;

  /// TODO: Output format (e.g. mp3_44100_128); set Accept header in real API.
  static const String? _defaultOutputFormat = null;

  bool get isIdle => _state == TtsState.idle;
  bool get isLoading => _state == TtsState.loading;
  bool get isPlaying => _state == TtsState.playing;
  bool get isPaused => _state == TtsState.paused;
  bool get isError => _state == TtsState.error;

  void _onPlayerStateChanged() {
    switch (_audioPlayer.state) {
      case AudioPlaybackState.idle:
        _setState(TtsState.idle);
        break;
      case AudioPlaybackState.playing:
        _setState(TtsState.playing);
        break;
      case AudioPlaybackState.paused:
        _setState(TtsState.paused);
        break;
      case AudioPlaybackState.stopped:
        _setState(TtsState.idle);
        break;
    }
  }

  void _setState(TtsState value) {
    if (_state == value) return;
    _state = value;
    if (value != TtsState.error) _errorMessage = null;
    notifyListeners();
  }

  /// Called when user taps the listen button. Idle → start synthesis; playing → pause; paused → resume.
  /// No-op while loading (debounce).
  Future<void> toggleListen(String text) async {
    if (text.trim().isEmpty) return;

    if (_state == TtsState.loading) return;

    if (_state == TtsState.playing) {
      _audioPlayer.pause();
      return;
    }

    if (_state == TtsState.paused) {
      _audioPlayer.resume();
      return;
    }

    // Idle or error: start synthesis
    _setState(TtsState.loading);
    _errorMessage = null;

    try {
      final bytes = await _ttsService.synthesize(
        text: text,
        voiceId: _defaultVoiceId,
        modelId: _defaultModelId,
        outputFormat: _defaultOutputFormat,
      );
      if (bytes.isEmpty) {
        _setState(TtsState.error);
        _errorMessage = 'No audio received';
        return;
      }
      _audioPlayer.play(bytes);
    } catch (e, st) {
      debugPrint('TTS synthesize error: $e $st');
      _setState(TtsState.error);
      _errorMessage = e.toString();
    }
  }

  /// Stop playback and reset to idle.
  void stop() {
    _audioPlayer.stop();
    _setState(TtsState.idle);
  }

  @override
  void dispose() {
    _audioPlayer.removeListener(_onPlayerStateChanged);
    _audioPlayer.dispose();
    super.dispose();
  }
}

/// Default factory for the detail screen: uses [MockTtsService]. Replace with
/// a real TtsService (e.g. ElevenLabs) when integrating the API.
TtsController createDefaultTtsController() {
  return TtsController(ttsService: MockTtsService());
}
