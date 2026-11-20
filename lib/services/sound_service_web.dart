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

/// Web Speech Synthesis + Procedural Retro Game Vocal Chatter synthesizer
void speakCustomerTextImpl(
  String text, {
  double pitch = 1.0,
  double rate = 1.0,
}) {
  // 1. Play cute procedural retro vocal chatter blips through Web Audio API
  _playVocalChatterBlips(pitch: pitch, text: text);

  // 2. Play natural spoken Filipino voice through browser SpeechSynthesis API
  _speakWithWebSpeech(text, pitch: pitch, rate: rate);
}

void _speakWithWebSpeech(
  String rawText, {
  required double pitch,
  required double rate,
}) {
  try {
    final synth =
        globalContext.getProperty('speechSynthesis'.toJS) as JSObject?;
    if (synth == null || synth.isUndefinedOrNull) return;

    // Clean emojis and symbols so speech synthesizer speaks clear Tagalog
    String cleanText = rawText
        .replaceAll(
          RegExp(
            r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[💵📱📝🍚🥤🍫☕🥚🛍️✅🔴🟢🚪🚚🎺📦]',
            unicode: true,
          ),
          '',
        )
        .replaceAll('—', ', ')
        .replaceAll('–', ', ')
        .replaceAll('GCash', 'G Cash')
        .trim();

    if (cleanText.isEmpty) return;

    // Cancel previous speech so speech does not pile up
    try {
      synth.callMethod('cancel'.toJS);
    } catch (_) {}

    final utterCtor =
        globalContext.getProperty('SpeechSynthesisUtterance'.toJS)
            as JSFunction?;
    if (utterCtor == null || utterCtor.isUndefinedOrNull) return;

    final utterance = utterCtor.callAsConstructor<JSObject>(cleanText.toJS);
    utterance.setProperty('lang'.toJS, 'fil-PH'.toJS);
    utterance.setProperty('pitch'.toJS, pitch.toJS);
    utterance.setProperty('rate'.toJS, rate.toJS);
    utterance.setProperty('volume'.toJS, 1.0.toJS);

    // Try to find a Filipino/Tagalog voice if installed
    try {
      final voices = synth.callMethod<JSAny>('getVoices'.toJS);
      if (voices != null && !voices.isUndefinedOrNull) {
        final length =
            (voices as JSObject).getProperty('length'.toJS) as JSNumber?;
        final count = length?.toDartInt ?? 0;
        for (int i = 0; i < count; i++) {
          final v = (voices as JSObject).callMethod<JSObject>(
            'item'.toJS,
            i.toJS,
          );
          if (v != null && !v.isUndefinedOrNull) {
            final vLang =
                (v.getProperty('lang'.toJS) as JSString?)?.toDart ?? '';
            if (vLang.toLowerCase().startsWith('fil') ||
                vLang.toLowerCase().startsWith('tl')) {
              utterance.setProperty('voice'.toJS, v);
              break;
            }
          }
        }
      }
    } catch (_) {}

    synth.callMethod('speak'.toJS, utterance);
  } catch (_) {
    // Autoplay or speech policy fallback
  }
}

void _playVocalChatterBlips({
  required double pitch,
  required String text,
}) {
  try {
    final audioCtxCtor =
        globalContext.getProperty('AudioContext'.toJS) ??
        globalContext.getProperty('webkitAudioContext'.toJS);
    if (audioCtxCtor == null || audioCtxCtor.isUndefinedOrNull) return;

    final ctx = (audioCtxCtor as JSFunction).callAsConstructor<JSObject>();
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
