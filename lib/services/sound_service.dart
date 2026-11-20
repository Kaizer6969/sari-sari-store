import 'sound_service_stub.dart'
    if (dart.library.js_interop) 'sound_service_web.dart'
    as impl;

/// Plays synthesized retro sound effects and speech audio
class SoundService {
  SoundService._();

  /// Plays a realistic dual-tone delivery truck air horn ("HONK! HOOOONK!")
  static void playTruckHorn() {
    impl.playTruckHornImpl();
  }

  /// Plays customer dialogue speech (browser Web Speech API + procedural retro vocal blips)
  static void speakCustomerText(
    String text, {
    double pitch = 1.0,
    double rate = 1.0,
  }) {
    impl.speakCustomerTextImpl(text, pitch: pitch, rate: rate);
  }
}
