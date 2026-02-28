import 'dart:typed_data';

/// Abstract Text-to-Speech service, designed for ElevenLabs API integration.
///
/// When integrating ElevenLabs:
/// - Use [synthesize] to call POST https://api.elevenlabs.io/v1/text-to-speech/{voice_id}
/// - Headers: xi-api-key: <API_KEY>, Content-Type: application/json, Accept: audio/mpeg (or output_format)
/// - Body: JSON with "text", optional "model_id"
/// - API key: load from env (e.g. dotenv) or secure storage — do NOT hardcode.
/// - Voice ID / model ID: configure in app config or constants; see ElevenLabs docs for available values.
abstract class TtsService {
  /// Synthesizes [text] to audio bytes using the given [voiceId].
  ///
  /// Optional [modelId] and [outputFormat] match ElevenLabs API; use defaults
  /// or app config when plugging in the real API.
  ///
  /// Returns raw audio bytes (e.g. MP3). For ElevenLabs: typically mp3_44100_128
  /// or similar; set Accept header and parse response.bytes.
  Future<Uint8List> synthesize({
    required String text,
    required String voiceId,
    String? modelId,
    String? outputFormat,
  });
}
