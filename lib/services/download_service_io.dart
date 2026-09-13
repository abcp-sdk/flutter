import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../api.dart';

/// Downloads authenticated files (release assets, source tarballs) through
/// the gateway into the PUBLIC Downloads collection.
///
/// Dart streams the bytes (the in-app HTTP stack trusts the private CA and
/// carries the gateway token — DownloadManager can do neither), then hands
/// the temp file to the native side which inserts it into MediaStore
/// (API 29+) or the app-external Downloads dir (legacy).
class DownloadService {
  static const _channel = MethodChannel('dev.easylab.app/downloads');

  DownloadService(this.api);
  final AgentBindApi api;

  /// Downloads [path] (relative to the gateway base URL) and publishes it
  /// as [displayName]. Returns a human-readable location (content URI or
  /// file path). Throws on any failure; callers surface a snackbar.
  Future<String> download({
    required String path,
    required String displayName,
    String mimeType = 'application/octet-stream',
    void Function(int received, int total)? onProgress,
  }) async {
    final tmpDir = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final tmp = File('${tmpDir.path}/dl-$stamp-${displayName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')}');
    final bytes = await api.fetchFileBytes(path);
    final sink = tmp.openWrite();
    try {
      sink.add(bytes);
    } catch (e) {
      await sink.close();
      await _deleteQuiet(tmp);
      rethrow;
    }
    await sink.close();
    try {
      final where = await _channel.invokeMethod<String>('saveToDownloads', {
        'src': tmp.path,
        'name': displayName,
        'mime': mimeType,
      });
      return where ?? displayName;
    } finally {
      await _deleteQuiet(tmp);
    }
  }

  static Future<void> _deleteQuiet(File f) async {
    try {
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}
