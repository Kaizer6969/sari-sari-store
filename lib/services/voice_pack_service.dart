import 'voice_pack_service_stub.dart'
    if (dart.library.js_interop) 'voice_pack_service_web.dart'
    as impl;

/// Manages recorded voice clips for customer personas (browser mic recording)
class VoicePackService {
  VoicePackService._();

  /// True if a clip has been recorded for [personaId] + [clipType]
  static Future<bool> hasRecording(String personaId, String clipType) =>
      impl.hasRecordingImpl(personaId, clipType);

  /// Play a previously recorded clip
  static Future<void> playRecording(String personaId, String clipType) =>
      impl.playRecordingImpl(personaId, clipType);

  /// Play if a clip exists; returns true if played, false if no clip recorded
  static Future<bool> playIfAvailable(String personaId, String clipType) =>
      impl.playIfAvailableImpl(personaId, clipType);

  /// Start recording from microphone (browser getUserMedia + MediaRecorder)
  static Future<void> startRecording() => impl.startRecordingImpl();

  /// Stop recording and return the data URL (base64 audio), or null on error
  static Future<String?> stopRecording() => impl.stopRecordingImpl();

  /// Save a recording data URL to persistent storage
  static Future<void> saveRecording(
    String personaId,
    String clipType,
    String dataUrl,
  ) => impl.saveRecordingImpl(personaId, clipType, dataUrl);

  /// Delete a recording
  static Future<void> deleteRecording(String personaId, String clipType) =>
      impl.deleteRecordingImpl(personaId, clipType);

  /// Whether the microphone is currently recording
  static bool get isRecording => impl.isRecordingImpl;
}
