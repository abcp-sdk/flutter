import 'dart:async';
import 'dart:io';

import 'package:record/record.dart';
import 'package:record_platform_interface/record_platform_interface.dart'
    show Amplitude;

import '../models.dart';

/// Voice recorder for the chat composer: records a WAV clip to a temp file via
/// the `record` package, then hands it to the caller as an [UploadedFileSource]
/// so it flows through the normal attachment upload path (file:<code>).
class VoiceRecorder {
  final AudioRecorder _recorder = AudioRecorder();
  String? _path;
  final DateTime _startedAt = DateTime.now();
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  double _amplitudeDb = -120;
  StreamSubscription<Amplitude>? _ampSub;

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
    if (!await hasPermission()) return false;
    final dir = await Directory.systemTemp.createTemp('voice');
    final file = '${dir.path}/voice-${DateTime.now().millisecondsSinceEpoch}.wav';
    try {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: file,
      );
    } catch (_) {
      return false;
    }
    _path = file;
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
    final path = _path;
    if (path == null) return null;
    _path = null;
    _ticker?.cancel();
    _ticker = null;
    await _ampSub?.cancel().catchError((_) {});
    _ampSub = null;
    try {
      await _recorder.stop();
    } catch (_) {}
    final f = File(path);
    if (!await f.exists()) return null;
    final len = await f.length();
    // Under ~0.4s of 16kHz mono 16-bit ≈ 12.8KB — treat as an accidental tap.
    if (len < 12800) {
      unawaited(f.delete().catchError((Object _) => f));
      return null;
    }
    final name =
        'voice-${DateTime.now().millisecondsSinceEpoch}.wav';
    return UploadedFileSource(
      path: path,
      name: name,
      mimeType: 'audio/wav',
    );
  }

  /// Cancel: stop recording and delete the file.
  Future<void> cancel() async {
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
      unawaited(File(path).delete().catchError((Object _) => File(path)));
    }
  }

  Future<void> dispose() async {
    await cancel();
    _recorder.dispose();
  }
}
