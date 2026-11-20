import 'sound_service_stub.dart'
    if (dart.library.js_interop) 'sound_service_web.dart'
    as impl;

/// Plays synthesized retro sound effects and customer speech audio
class SoundService {
  SoundService._();

  /// Unlocks audio playback on user interaction (especially on iOS / mobile Safari)
  static void unlockAudio() {
    impl.unlockAudioImpl();
  }

  /// Plays a realistic dual-tone delivery truck air horn ("HONK! HOOOONK!")
  static void playTruckHorn() {
    impl.playTruckHornImpl();
  }

  /// Plays customer dialogue audio:
  /// 1. If user recorded a voice clip → plays their recording
  /// 2. Otherwise → plays retro game vocal chatter blips
  /// (Web Speech TTS removed — users record their own voices via Voice Studio)
  static void speakCustomerText(
    String text, {
    double pitch = 1.0,
    double rate = 1.0,
    String? personaId,
    String? clipType,
  }) {
    impl.speakCustomerTextImpl(
      text,
      pitch: pitch,
      rate: rate,
      personaId: personaId,
      clipType: clipType,
    );
  }

  /// Plays metallic coin clink when taking or giving coins
  static void playCoinSound() {
    impl.playCoinSoundImpl();
  }

  /// Plays paper bill rustle / slide sound
  static void playBillSound() {
    impl.playBillSoundImpl();
  }

  /// Plays classic retro cash register bell "Ka-ching!"
  static void playRegisterKaChing() {
    impl.playRegisterKaChingImpl();
  }

  /// Plays short error buzzer for wrong change
  static void playErrorBuzz() {
    impl.playErrorBuzzImpl();
  }
}
