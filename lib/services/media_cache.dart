import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../api.dart';

/// Fetches agent-native file bytes (authenticated Connect unary GetFile) and
/// materialises them as a local temp file so media players (just_audio,
/// video_player) which take a path/URI can seek, loop and report duration.
///
/// Results are cached per code for the app session; the temp file lives under
/// the app cache dir and is deleted on eviction.
class MediaCache {
  MediaCache(this.api);
  final AgentBindApi api;

  static final Map<String, File> _files = {};
  static final Map<String, Future<File>> _inflight = {};

  /// Type/name hint for the temp file extension (players sniff by extension).
  static String _ext(String? mime, String? name) {
    final n = name ?? '';
    final dot = n.lastIndexOf('.');
    if (dot > 0 && dot < n.length - 1) return n.substring(dot);
    final m = mime ?? '';
    if (m == 'audio/wav' || m == 'audio/x-wav') return '.wav';
    if (m == 'audio/mpeg') return '.mp3';
    if (m == 'audio/mp4' || m == 'audio/aac') return '.m4a';
    if (m == 'audio/ogg') return '.ogg';
    if (m == 'video/mp4') return '.mp4';
    if (m == 'video/webm') return '.webm';
    return '.bin';
  }

  static File? cached(String code) => _files[code];

  Future<File> fileFor(String code, {String? mime, String? name}) {
    final hit = _files[code];
    if (hit != null) return Future.value(hit);
    final pending = _inflight[code];
    if (pending != null) return pending;
    final fut = _download(code, mime, name).whenComplete(() {
      _inflight.remove(code);
    });
    _inflight[code] = fut;
    return fut;
  }

  Future<File> _download(String code, String? mime, String? name) async {
    final bytes = await api.fetchFileBytes(code);
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/file-$code${_ext(mime, name)}');
    if (!await f.exists() || (await f.length()) != bytes.length) {
      await f.writeAsBytes(Uint8List.fromList(bytes), flush: true);
    }
    _files[code] = f;
    // Bounded cache: evict oldest entries beyond a small cap.
    while (_files.length > 24) {
      final oldest = _files.keys.first;
      final old = _files.remove(oldest);
      if (old != null) old.delete().catchError((Object _) => old);
    }
    return f;
  }
}
