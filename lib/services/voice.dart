import 'dart:async';

import 'package:record/record.dart';
import 'package:record_platform_interface/record_platform_interface.dart'
    show Amplitude;

import '../models.dart';
import 'voice_io.dart'
    if (dart.library.js_interop) 'voice_web.dart' as platform;

/// Voice recorder for the chat composer: records a WAV clip via the `record`
/// package, then hands it to the caller as an [UploadedFileSource] so it flows
/// through the normal attachment upload path (file:<code>).
///
/// Native platforms record to a temp FILE (path); web has no filesystem, so
/// the recorder returns a blob URL which we fetch into bytes. [stop] resolves
/// both into an [UploadedFileSource] with `bytes` (always) and `path` (native).
class VoiceRecorder {
  final AudioRecorder _recorder = AudioRecorder();
  String? _path;
  DateTime _startedAt = DateTime.now();
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  double _amplitudeDb = -120;
  StreamSubscription<Amplitude>? _ampSub;

  /// The pending [start] call. [stop]/[cancel] await this so a fast
  /// press-release during the permission prompt can't race the recorder into
  /// recording forever.
  Future<bool>? _starting;

  bool get isRecording => _path != null;
  Duration get elapsed => _elapsed;
  /// Last amplitude level 0..1 (coarse; drives a simple level indicator).
  /// `Amplitude.current` is dBFS (typically -120..0), mapped to 0..1 over
  /// -40dB..0dB which is the useful speech range.
  double get level {
    const floorDb = -40.0;
    final db = _amplitudeDb.clamp(floorDb, 0.0);
    return ((db - floorDb) / -floorDb).clamp(0.0, 1.0);
  }

  Future<bool> hasPermission() => _recorder.hasPermission();

  /// Start recording. Returns false when permission was denied.
  Future<bool> start() async {
    if (isRecording) return true;
    if (_starting != null) return _starting!;
    final f = _start();
    _starting = f;
    try {
      return await f;
    } finally {
      _starting = null;
    }
  }

  Future<bool> _start() async {
    if (!await hasPermission()) return false;
    // Web ignores the path (recorder returns a blob URL); native writes here.
    final path = await platform.tempVoicePath();
    try {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );
    } catch (_) {
      return false;
    }
    _path = path;
    // Reset the clock at the actual start; a stale `_startedAt` (from
    // construction) otherwise makes the on-screen seconds wildly wrong.
    _startedAt = DateTime.now();
    _elapsed = Duration.zero;
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      _elapsed = DateTime.now().difference(_startedAt);
    });
    _ampSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 200))
        .listen((a) => _amplitudeDb = a.current);
    return true;
  }

  /// Stop and return the recording as an attachment source, or null when the
  /// clip is too short / nothing was recorded.
  Future<UploadedFileSource?> stop() async {
    // Wait for an in-flight start so we never miss the file it just created.
    if (_starting != null) {
      try {
        await _starting;
      } catch (_) {}
    }
    final path = _path;
    if (path == null) return null;
    _path = null;
    _ticker?.cancel();
    _ticker = null;
    await _ampSub?.cancel().catchError((_) {});
    _ampSub = null;
    String? result;
    try {
      result = await _recorder.stop();
    } catch (_) {}
    // On web `result` is a blob URL; native returns the path.
    final blobOrPath = result ?? path;
    final bytes = await platform.readVoiceBytes(blobOrPath, path);
    if (bytes == null || bytes.length < 12800) {
      // Under ~0.4s of 16kHz mono 16-bit ≈ 12.8KB — an accidental tap.
      return null;
    }
    final name = 'voice-${DateTime.now().millisecondsSinceEpoch}.wav';
    return UploadedFileSource(
      path: path,
      name: name,
      mimeType: 'audio/wav',
      bytes: bytes,
    );
  }

  /// Cancel: stop recording and discard the clip.
  Future<void> cancel() async {
    if (_starting != null) {
      try {
        await _starting;
      } catch (_) {}
    }
    final path = _path;
    _path = null;
    _ticker?.cancel();
    _ticker = null;
    await _ampSub?.cancel().catchError((_) {});
    _ampSub = null;
    try {
      await _recorder.stop();
    } catch (_) {}
    if (path != null) {
      unawaited(platform.deleteVoiceFile(path));
    }
  }

  Future<void> dispose() async {
    await cancel();
    _recorder.dispose();
  }
}
