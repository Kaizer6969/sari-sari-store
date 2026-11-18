import 'sound_service_stub.dart'
    if (dart.library.js_interop) 'sound_service_web.dart'
    as impl;

/// Plays synthesized retro sound effects (like the delivery truck horn!)
class SoundService {
  SoundService._();

  /// Plays a realistic dual-tone delivery truck air horn ("HONK! HOOOONK!")
  static void playTruckHorn() {
    impl.playTruckHornImpl();
  }
}
