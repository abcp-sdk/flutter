import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'media_handle.dart';

/// Web: no filesystem. Create an object URL for the bytes so network-based
/// viewers (Image.network and the video/audio players) can consume it.
Future<MediaHandle> materializeMedia(
  String key,
  Uint8List bytes, {
  String? mime,
  String? name,
}) async {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: mime ?? 'application/octet-stream'),
  );
  final url = web.URL.createObjectURL(blob);
  return MediaHandle(bytes: bytes, uri: url);
}

ImageProvider imageProviderFor(MediaHandle handle) => NetworkImage(handle.uri!);
