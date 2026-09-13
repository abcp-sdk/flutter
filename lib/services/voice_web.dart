import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Web has no filesystem: the recorder's `start` path is ignored and `stop`
/// returns a blob URL. Return an empty path (note: `record_web` requires the
/// parameter but ignores it).
Future<String> tempVoicePath() async => '';

/// Fetch the blob URL the web recorder returned into raw bytes.
Future<Uint8List?> readVoiceBytes(String result, String fallbackPath) async {
  if (result.isEmpty) return null;
  final resp = await web.window.fetch(result.toJS).toDart;
  final buf = await resp.arrayBuffer().toDart;
  return buf.toDart.asUint8List();
}

/// Web: object URLs live for the document; nothing to delete here.
Future<void> deleteVoiceFile(String path) async {}
