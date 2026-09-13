import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import 'platform_media_io.dart'
    if (dart.library.js_interop) 'platform_media_web.dart' as impl;

/// A media blob made usable by the UI/players, platform-neutrally.
///
/// On native platforms the bytes are written to a temp file and [path] points
/// at it (just_audio / video_player / pdfx take a path). On the web there is no
/// filesystem: [path] is null and [uri] is an object URL (`blob:`) usable by
/// `Image.network` / video players, while [bytes] feeds in-memory rendering.
class MediaHandle {
  final Uint8List bytes;
  final String? path;
  final String? uri;
  const MediaHandle({required this.bytes, this.path, this.uri});
}

/// Materialise [bytes] as a [MediaHandle] for the current platform.
Future<MediaHandle> materializeMedia(
  String key,
  Uint8List bytes, {
  String? mime,
  String? name,
}) => impl.materializeMedia(key, bytes, mime: mime, name: name);

/// A ready-to-render image provider for [handle] (file on native, blob URL on
/// web).
ImageProvider imageProviderFor(MediaHandle handle) => impl.imageProviderFor(handle);

/// Extension hint from mime/name so players can sniff the format.
String mediaExt(String? mime, String? name) {
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
  if (m == 'image/png') return '.png';
  if (m == 'image/jpeg') return '.jpg';
  if (m == 'application/pdf') return '.pdf';
  return '.bin';
}
