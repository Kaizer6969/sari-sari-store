/// Non-web / test fallback — no microphone, no recordings

Future<bool> hasRecordingImpl(String pid, String cid) async => false;

Future<void> playRecordingImpl(String pid, String cid) async {}

Future<bool> playIfAvailableImpl(String pid, String cid) async => false;

Future<void> startRecordingImpl() async {}

Future<String?> stopRecordingImpl() async => null;

Future<void> saveRecordingImpl(String pid, String cid, String dataUrl) async {}

Future<void> deleteRecordingImpl(String pid, String cid) async {}

bool get isRecordingImpl => false;
