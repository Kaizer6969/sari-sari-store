import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'voice_pack_service_web.dart' as voicePack;

JSObject? _audioCtx;

JSObject? _getOrCreateAudioContext() {
  try {
    final existing = globalContext.getProperty('__gameAudioCtx'.toJS);
    if (existing != null && !existing.isUndefinedOrNull) {
      _audioCtx = existing as JSObject;
    }

    if (_audioCtx == null) {
      final audioCtxCtor =
          globalContext.getProperty('AudioContext'.toJS) ??
          globalContext.getProperty('webkitAudioContext'.toJS);
      if (audioCtxCtor != null && !audioCtxCtor.isUndefinedOrNull) {
        _audioCtx = (audioCtxCtor as JSFunction).callAsConstructor<JSObject>();
        globalContext.setProperty('__gameAudioCtx'.toJS, _audioCtx);
      }
    }

    if (_audioCtx != null) {
      final state =
          (_audioCtx!.getProperty('state'.toJS) as JSString?)?.toDart;
      if (state == 'suspended') {
        _audioCtx!.callMethod('resume'.toJS);
      }
    }
    return _audioCtx;
  } catch (_) {
    return null;
  }
}

/// Unlocks the Web Audio context upon the first user interaction (critical for iOS Safari)
void unlockAudioImpl() {
  _getOrCreateAudioContext();
}

/// Web Audio API synthesizer for an authentic dual-tone delivery truck air horn ("HONK! HOOOONK!")
void playTruckHornImpl() {
  try {
    final ctx = _getOrCreateAudioContext();
    if (ctx == null) return;

    final now = (ctx.getProperty('currentTime'.toJS) as JSNumber).toDartDouble;
    final destination = ctx.getProperty('destination'.toJS)!;

    // Schedule two authentic truck horn blasts: short "HONK!" then longer "HOOOONK!"
    _playHornBlast(ctx, destination, startTime: now + 0.02, duration: 0.28);
    _playHornBlast(ctx, destination, startTime: now + 0.42, duration: 0.55);
  } catch (_) {
    // Ignore audio context errors
  }
}

void _playHornBlast(
  JSObject ctx,
  JSAny destination, {
  required double startTime,
  required double duration,
}) {
  // Master gain for this blast with smooth attack & release
  final gain = ctx.callMethod<JSObject>('createGain'.toJS);
  final gainParam = gain.getProperty('gain'.toJS) as JSObject;
  gainParam.callMethod('setValueAtTime'.toJS, 0.0001.toJS, startTime.toJS);
  gainParam.callMethod(
    'linearRampToValueAtTime'.toJS,
    0.22.toJS,
    (startTime + 0.035).toJS,
  );
  gainParam.callMethod(
    'setValueAtTime'.toJS,
    0.20.toJS,
    (startTime + duration - 0.06).toJS,
  );
  gainParam.callMethod(
    'exponentialRampToValueAtTime'.toJS,
    0.0001.toJS,
    (startTime + duration).toJS,
  );

  // Warm brass low-pass filter so sawtooth sounds like a deep cargo truck air horn
  final filter = ctx.callMethod<JSObject>('createBiquadFilter'.toJS);
  filter.setProperty('type'.toJS, 'lowpass'.toJS);
  final freqParam = filter.getProperty('frequency'.toJS) as JSObject;
  freqParam.callMethod('setValueAtTime'.toJS, 920.0.toJS, startTime.toJS);

  filter.callMethod('connect'.toJS, gain);
  gain.callMethod('connect'.toJS, destination);

  // Classic dual-tone cargo truck horn chord: F#3 (185 Hz) + A#3 (233 Hz)
  for (final hz in [185.0, 233.0]) {
    final osc = ctx.callMethod<JSObject>('createOscillator'.toJS);
    osc.setProperty('type'.toJS, 'sawtooth'.toJS);
    final oscFreq = osc.getProperty('frequency'.toJS) as JSObject;
    oscFreq.callMethod('setValueAtTime'.toJS, hz.toJS, startTime.toJS);
    osc.callMethod('connect'.toJS, filter);
    osc.callMethod('start'.toJS, startTime.toJS);
    osc.callMethod('stop'.toJS, (startTime + duration + 0.02).toJS);
  }
}

/// Customer dialogue audio: plays user's recorded voice if available,
/// otherwise plays procedural retro game vocal chatter blips.
void speakCustomerTextImpl(
  String text, {
  double pitch = 1.0,
  double rate = 1.0,
  String? personaId,
  String? clipType,
}) {
  if (personaId != null && clipType != null) {
    // Try user's recorded voice first; fall back to retro chatter blips
    voicePack.playIfAvailableImpl(personaId, clipType).then((played) {
      if (!played) {
        _playVocalChatterBlips(pitch: pitch, text: text);
      }
    });
  } else {
    // No persona info — just play retro chatter blips
    _playVocalChatterBlips(pitch: pitch, text: text);
  }
}

void _playVocalChatterBlips({
  required double pitch,
  required String text,
}) {
  try {
    final ctx = _getOrCreateAudioContext();
    if (ctx == null) return;

    final now = (ctx.getProperty('currentTime'.toJS) as JSNumber).toDartDouble;
    final destination = ctx.getProperty('destination'.toJS)!;

    final words =
        text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final blipCount = (words * 2).clamp(4, 9);
    final baseFreq = (260.0 * pitch).clamp(140.0, 750.0);

    for (int i = 0; i < blipCount; i++) {
      final startTime = now + (i * 0.072);
      const duration = 0.045;

      final gain = ctx.callMethod<JSObject>('createGain'.toJS);
      final gainParam = gain.getProperty('gain'.toJS) as JSObject;
      gainParam.callMethod('setValueAtTime'.toJS, 0.0001.toJS, startTime.toJS);
      gainParam.callMethod(
        'linearRampToValueAtTime'.toJS,
        0.08.toJS,
        (startTime + 0.008).toJS,
      );
      gainParam.callMethod(
        'exponentialRampToValueAtTime'.toJS,
        0.0001.toJS,
        (startTime + duration).toJS,
      );

      final filter = ctx.callMethod<JSObject>('createBiquadFilter'.toJS);
      filter.setProperty('type'.toJS, 'bandpass'.toJS);
      final freqParam = filter.getProperty('frequency'.toJS) as JSObject;
      final qParam = filter.getProperty('Q'.toJS) as JSObject;

      final inflection =
          1.0 + (i % 3 == 0 ? 0.08 : (i % 3 == 1 ? -0.06 : 0.02));
      freqParam.callMethod(
        'setValueAtTime'.toJS,
        (baseFreq * inflection * 2.2).toJS,
        startTime.toJS,
      );
      qParam.callMethod('setValueAtTime'.toJS, 2.5.toJS, startTime.toJS);

      filter.callMethod('connect'.toJS, gain);
      gain.callMethod('connect'.toJS, destination);

      final osc = ctx.callMethod<JSObject>('createOscillator'.toJS);
      osc.setProperty('type'.toJS, 'triangle'.toJS);
      final oscFreq = osc.getProperty('frequency'.toJS) as JSObject;
      oscFreq.callMethod(
        'setValueAtTime'.toJS,
        (baseFreq * inflection).toJS,
        startTime.toJS,
      );
      osc.callMethod('connect'.toJS, filter);
      osc.callMethod('start'.toJS, startTime.toJS);
      osc.callMethod('stop'.toJS, (startTime + duration + 0.01).toJS);
    }
  } catch (_) {
    // Ignore audio context errors
  }
}
