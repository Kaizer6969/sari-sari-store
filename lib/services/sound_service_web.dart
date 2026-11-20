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

/// Metallic coin ping sound
void playCoinSoundImpl() {
  try {
    final ctx = _getOrCreateAudioContext();
    if (ctx == null) return;

    final now = (ctx.getProperty('currentTime'.toJS) as JSNumber).toDartDouble;
    final destination = ctx.getProperty('destination'.toJS)!;

    final gain = ctx.callMethod<JSObject>('createGain'.toJS);
    final gainParam = gain.getProperty('gain'.toJS) as JSObject;
    gainParam.callMethod('setValueAtTime'.toJS, 0.18.toJS, now.toJS);
    gainParam.callMethod(
      'exponentialRampToValueAtTime'.toJS,
      0.0001.toJS,
      (now + 0.12).toJS,
    );
    gain.callMethod('connect'.toJS, destination);

    // Dual frequencies for metallic resonance (2400 Hz + 3600 Hz)
    for (final freq in [2400.0, 3600.0]) {
      final osc = ctx.callMethod<JSObject>('createOscillator'.toJS);
      osc.setProperty('type'.toJS, 'sine'.toJS);
      final oscFreq = osc.getProperty('frequency'.toJS) as JSObject;
      oscFreq.callMethod('setValueAtTime'.toJS, freq.toJS, now.toJS);
      osc.callMethod('connect'.toJS, gain);
      osc.callMethod('start'.toJS, now.toJS);
      osc.callMethod('stop'.toJS, (now + 0.12).toJS);
    }
  } catch (_) {}
}

/// Paper bill flutter / slide sound
void playBillSoundImpl() {
  try {
    final ctx = _getOrCreateAudioContext();
    if (ctx == null) return;

    final now = (ctx.getProperty('currentTime'.toJS) as JSNumber).toDartDouble;
    final destination = ctx.getProperty('destination'.toJS)!;

    final gain = ctx.callMethod<JSObject>('createGain'.toJS);
    final gainParam = gain.getProperty('gain'.toJS) as JSObject;
    gainParam.callMethod('setValueAtTime'.toJS, 0.12.toJS, now.toJS);
    gainParam.callMethod(
      'exponentialRampToValueAtTime'.toJS,
      0.0001.toJS,
      (now + 0.08).toJS,
    );

    final filter = ctx.callMethod<JSObject>('createBiquadFilter'.toJS);
    filter.setProperty('type'.toJS, 'bandpass'.toJS);
    final freqParam = filter.getProperty('frequency'.toJS) as JSObject;
    freqParam.callMethod('setValueAtTime'.toJS, 480.0.toJS, now.toJS);

    filter.callMethod('connect'.toJS, gain);
    gain.callMethod('connect'.toJS, destination);

    final osc = ctx.callMethod<JSObject>('createOscillator'.toJS);
    osc.setProperty('type'.toJS, 'triangle'.toJS);
    final oscFreq = osc.getProperty('frequency'.toJS) as JSObject;
    oscFreq.callMethod('setValueAtTime'.toJS, 380.0.toJS, now.toJS);
    oscFreq.callMethod('linearRampToValueAtTime'.toJS, 620.0.toJS, (now + 0.07).toJS);

    osc.callMethod('connect'.toJS, filter);
    osc.callMethod('start'.toJS, now.toJS);
    osc.callMethod('stop'.toJS, (now + 0.08).toJS);
  } catch (_) {}
}

/// Retro cash register bell "Ka-ching!"
void playRegisterKaChingImpl() {
  try {
    final ctx = _getOrCreateAudioContext();
    if (ctx == null) return;

    final now = (ctx.getProperty('currentTime'.toJS) as JSNumber).toDartDouble;
    final destination = ctx.getProperty('destination'.toJS)!;

    // First ding: 1046.5 Hz (C6)
    final osc1 = ctx.callMethod<JSObject>('createOscillator'.toJS);
    osc1.setProperty('type'.toJS, 'sine'.toJS);
    final f1 = osc1.getProperty('frequency'.toJS) as JSObject;
    f1.callMethod('setValueAtTime'.toJS, 1046.5.toJS, now.toJS);

    final gain1 = ctx.callMethod<JSObject>('createGain'.toJS);
    final g1 = gain1.getProperty('gain'.toJS) as JSObject;
    g1.callMethod('setValueAtTime'.toJS, 0.22.toJS, now.toJS);
    g1.callMethod('exponentialRampToValueAtTime'.toJS, 0.001.toJS, (now + 0.25).toJS);

    osc1.callMethod('connect'.toJS, gain1);
    gain1.callMethod('connect'.toJS, destination);
    osc1.callMethod('start'.toJS, now.toJS);
    osc1.callMethod('stop'.toJS, (now + 0.25).toJS);

    // Second chime: 1318.5 Hz (E6) & 2093.0 Hz (C7) with longer sustain
    final t2 = now + 0.08;
    for (final freq in [1318.5, 2093.0]) {
      final osc2 = ctx.callMethod<JSObject>('createOscillator'.toJS);
      osc2.setProperty('type'.toJS, 'sine'.toJS);
      final f2 = osc2.getProperty('frequency'.toJS) as JSObject;
      f2.callMethod('setValueAtTime'.toJS, freq.toJS, t2.toJS);

      final gain2 = ctx.callMethod<JSObject>('createGain'.toJS);
      final g2 = gain2.getProperty('gain'.toJS) as JSObject;
      g2.callMethod('setValueAtTime'.toJS, 0.25.toJS, t2.toJS);
      g2.callMethod('exponentialRampToValueAtTime'.toJS, 0.0001.toJS, (t2 + 0.65).toJS);

      osc2.callMethod('connect'.toJS, gain2);
      gain2.callMethod('connect'.toJS, destination);
      osc2.callMethod('start'.toJS, t2.toJS);
      osc2.callMethod('stop'.toJS, (t2 + 0.65).toJS);
    }
  } catch (_) {}
}

/// Error buzzer for incorrect change
void playErrorBuzzImpl() {
  try {
    final ctx = _getOrCreateAudioContext();
    if (ctx == null) return;

    final now = (ctx.getProperty('currentTime'.toJS) as JSNumber).toDartDouble;
    final destination = ctx.getProperty('destination'.toJS)!;

    final osc = ctx.callMethod<JSObject>('createOscillator'.toJS);
    osc.setProperty('type'.toJS, 'sawtooth'.toJS);
    final f = osc.getProperty('frequency'.toJS) as JSObject;
    f.callMethod('setValueAtTime'.toJS, 130.0.toJS, now.toJS);

    final gain = ctx.callMethod<JSObject>('createGain'.toJS);
    final g = gain.getProperty('gain'.toJS) as JSObject;
    g.callMethod('setValueAtTime'.toJS, 0.18.toJS, now.toJS);
    g.callMethod('exponentialRampToValueAtTime'.toJS, 0.001.toJS, (now + 0.22).toJS);

    osc.callMethod('connect'.toJS, gain);
    gain.callMethod('connect'.toJS, destination);
    osc.callMethod('start'.toJS, now.toJS);
    osc.callMethod('stop'.toJS, (now + 0.22).toJS);
  } catch (_) {}
}
