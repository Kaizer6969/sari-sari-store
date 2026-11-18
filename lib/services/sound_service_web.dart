import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Web Audio API synthesizer for an authentic dual-tone delivery truck air horn ("HONK! HOOOONK!")
void playTruckHornImpl() {
  try {
    final audioCtxCtor =
        globalContext.getProperty('AudioContext'.toJS) ??
        globalContext.getProperty('webkitAudioContext'.toJS);
    if (audioCtxCtor == null || audioCtxCtor.isUndefinedOrNull) return;

    final ctx = (audioCtxCtor as JSFunction).callAsConstructor<JSObject>();
    final now = (ctx.getProperty('currentTime'.toJS) as JSNumber).toDartDouble;
    final destination = ctx.getProperty('destination'.toJS)!;

    // Schedule two authentic truck horn blasts: short "HONK!" then longer "HOOOONK!"
    _playHornBlast(ctx, destination, startTime: now + 0.02, duration: 0.28);
    _playHornBlast(ctx, destination, startTime: now + 0.42, duration: 0.55);
  } catch (_) {
    // Ignore audio context errors (e.g. autoplay policy before first click)
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
