import 'dart:async';
import 'dart:typed_data';

import '../api.dart';
import 'local_bytes_io.dart'
    if (dart.library.js_interop) 'local_bytes_web.dart' as localbytes;
import 'media_handle.dart';

/// Fetches agent-native file bytes (authenticated Connect unary GetFile) and
/// materialises them as a [MediaHandle] (temp file on native, blob URL on web)
/// so media viewers/players can consume them. [localPath] short-circuits the
/// fetch for a just-picked attachment (not yet uploaded).
///
/// Results are cached per code for the app session (bounded).
class MediaCache {
  MediaCache(this.api);
  final AgentBindApi api;

  static final Map<String, MediaHandle> _handles = {};
  static final Map<String, Future<MediaHandle>> _inflight = {};

  static MediaHandle? cached(String code) => _handles[code];

  Future<MediaHandle> fileFor(String code,
      {String? mime, String? name, String? localPath}) {
    // Just-picked attachment: bytes may be on disk (native) — but the caller
    // passes them as a path; we materialise via the platform helper.
    final key = code.isNotEmpty ? code : 'local:${localPath ?? name ?? ''}';
    final hit = _handles[key];
    if (hit != null) return Future.value(hit);
    final pending = _inflight[key];
    if (pending != null) return pending;
    final fut = _resolve(key, code, mime, name, localPath).whenComplete(() {
      _inflight.remove(key);
    });
    _inflight[key] = fut;
    return fut;
  }

  Future<MediaHandle> _resolve(String key, String code, String? mime,
      String? name, String? localPath) async {
    Uint8List bytes;
    if (code.isEmpty && localPath != null && localPath.isNotEmpty) {
      bytes = await localbytes.readLocalBytes(localPath);
    } else {
      bytes = Uint8List.fromList(await api.fetchFileBytes(code));
    }
    final handle =
        await materializeMedia(key.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_'),
            bytes, mime: mime, name: name);
    _handles[key] = handle;
    while (_handles.length > 24) {
      final oldest = _handles.keys.first;
      _handles.remove(oldest);
    }
    return handle;
  }
}
