import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:async';

// ── Module-level recording state ──────────────────────────────────────────
JSObject? _recorder;
JSObject? _stream;
Completer<String?>? _blobCompleter;
bool _recording = false;

bool get isRecordingImpl => _recording;

// ── LocalStorage helper ───────────────────────────────────────────────────

JSObject? _ls() {
  try {
    final s = globalContext.getProperty('localStorage'.toJS);
    return (s != null && !s.isUndefinedOrNull) ? s as JSObject : null;
  } catch (_) {
    return null;
  }
}

String _k(String pid, String cid) => 'voice_${pid}_$cid';

// ── Has / Get / Save / Delete ─────────────────────────────────────────────

Future<bool> hasRecordingImpl(String pid, String cid) async {
  final s = _ls();
  if (s == null) return false;
  final v = s.callMethod<JSAny?>('getItem'.toJS, _k(pid, cid).toJS);
  return v != null && !v.isUndefinedOrNull;
}

String? _getSync(String pid, String cid) {
  final s = _ls();
  if (s == null) return null;
  final v = s.callMethod<JSAny?>('getItem'.toJS, _k(pid, cid).toJS);
  if (v == null || v.isUndefinedOrNull) return null;
  return (v as JSString).toDart;
}

Future<void> saveRecordingImpl(String pid, String cid, String dataUrl) async {
  _ls()?.callMethod<JSAny?>('setItem'.toJS, _k(pid, cid).toJS, dataUrl.toJS);
}

Future<void> deleteRecordingImpl(String pid, String cid) async {
  _ls()?.callMethod<JSAny?>('removeItem'.toJS, _k(pid, cid).toJS);
}

// ── Playback ──────────────────────────────────────────────────────────────

void _play(String dataUrl) {
  try {
    final ctor = globalContext.getProperty('Audio'.toJS);
    if (ctor == null || ctor.isUndefinedOrNull) return;
    final audio = (ctor as JSFunction).callAsConstructor<JSObject>(dataUrl.toJS);
    audio.setProperty('preload'.toJS, 'auto'.toJS);
    final playPromise = audio.callMethod<JSAny?>('play'.toJS);
    if (playPromise != null && !playPromise.isUndefinedOrNull) {
      (playPromise as JSPromise).toDart.catchError((_) => null);
    }
  } catch (_) {}
}

Future<void> playRecordingImpl(String pid, String cid) async {
  final url = _getSync(pid, cid);
  if (url != null) _play(url);
}

Future<bool> playIfAvailableImpl(String pid, String cid) async {
  final url = _getSync(pid, cid);
  if (url == null) return false;
  _play(url);
  return true;
}

// ── Recording (MediaRecorder API) ─────────────────────────────────────────

JSObject _newObj() =>
    (globalContext.getProperty('Object'.toJS) as JSFunction)
        .callAsConstructor<JSObject>();

Future<void> startRecordingImpl() async {
  if (_recording) await stopRecordingImpl();

  try {
    final nav = globalContext.getProperty('navigator'.toJS) as JSObject?;
    if (nav == null) return;
    final md = nav.getProperty('mediaDevices'.toJS) as JSObject?;
    if (md == null) return;

    // {audio: true}
    final constraints = _newObj();
    constraints.setProperty('audio'.toJS, true.toJS);

    // Request microphone access
    final promise = md.callMethod<JSAny>('getUserMedia'.toJS, constraints);
    final result = await (promise as JSPromise).toDart;
    _stream = result as JSObject?;
    if (_stream == null) return;

    // Create MediaRecorder
    final mrCtor =
        globalContext.getProperty('MediaRecorder'.toJS) as JSFunction?;
    if (mrCtor == null) {
      _releaseMic();
      return;
    }

    _recorder = mrCtor.callAsConstructor<JSObject>(_stream!);
    _blobCompleter = Completer<String?>();
    _recording = true;

    // When stop() is called, ondataavailable delivers the recorded blob
    _recorder!.setProperty(
      'ondataavailable'.toJS,
      ((JSAny event) {
        _handleBlob(event);
      }).toJS,
    );

    _recorder!.callMethod<JSAny?>('start'.toJS);
  } catch (_) {
    _recording = false;
    _safeDone(null);
    _releaseMic();
  }
}

void _handleBlob(JSAny event) {
  try {
    final blob = (event as JSObject).getProperty('data'.toJS);
    if (blob == null || blob.isUndefinedOrNull) {
      _safeDone(null);
      return;
    }

    // Convert Blob → base64 data URL via FileReader
    final frCtor = globalContext.getProperty('FileReader'.toJS) as JSFunction;
    final reader = frCtor.callAsConstructor<JSObject>();

    reader.setProperty(
      'onloadend'.toJS,
      ((JSAny _) {
        try {
          final res = reader.getProperty('result'.toJS);
          _safeDone(
            (res != null && !res.isUndefinedOrNull)
                ? (res as JSString).toDart
                : null,
          );
        } catch (_) {
          _safeDone(null);
        }
      }).toJS,
    );

    reader.callMethod<JSAny?>('readAsDataURL'.toJS, blob);
  } catch (_) {
    _safeDone(null);
  }
}

void _safeDone(String? value) {
  if (_blobCompleter != null && !_blobCompleter!.isCompleted) {
    _blobCompleter!.complete(value);
  }
}

Future<String?> stopRecordingImpl() async {
  if (!_recording || _recorder == null) return null;
  _recording = false;

  try {
    _recorder!.callMethod<JSAny?>('stop'.toJS);
  } catch (_) {}

  String? result;
  if (_blobCompleter != null && !_blobCompleter!.isCompleted) {
    result = await _blobCompleter!.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => null,
    );
  }

  _releaseMic();
  _recorder = null;
  _stream = null;
  _blobCompleter = null;
  return result;
}

void _releaseMic() {
  if (_stream == null) return;
  try {
    final tracks = _stream!.callMethod<JSObject>('getTracks'.toJS);
    tracks.callMethod<JSAny?>(
      'forEach'.toJS,
      ((JSAny track) {
        (track as JSObject).callMethod<JSAny?>('stop'.toJS);
      }).toJS,
    );
  } catch (_) {}
  _stream = null;
}
