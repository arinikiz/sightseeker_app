import 'dart:math';
import 'dart:typed_data';

import 'tts_service.dart';

/// Stub TTS implementation for UI development. Simulates latency and returns
/// dummy audio bytes so the listen flow can be tested without the real API.
///
/// Replace usage with a real implementation (e.g. [ElevenLabsTtsService]) that
/// calls POST https://api.elevenlabs.io/v1/text-to-speech/{voice_id} with
/// xi-api-key header and JSON body.
class MockTtsService implements TtsService {
  final Random _random = Random();

  @override
  Future<Uint8List> synthesize({
    required String text,
    required String voiceId,
    String? modelId,
    String? outputFormat,
  }) async {
    // Simulate network latency (600–1200 ms)
    await Future<void>.delayed(
      Duration(milliseconds: 600 + _random.nextInt(600)),
    );
    // Return minimal dummy bytes so playback layer can run (e.g. stub duration).
    // Real implementation will return actual MP3/audio bytes from ElevenLabs.
    return Uint8List.fromList(List.filled(128, 0));
  }
}
