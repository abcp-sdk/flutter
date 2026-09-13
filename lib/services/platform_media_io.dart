import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'media_handle.dart';

/// Native: write the bytes to a temp file so players/pdf readers can take a
/// path. Returns a handle carrying both the path and the raw bytes.
Future<MediaHandle> materializeMedia(
  String key,
  Uint8List bytes, {
  String? mime,
  String? name,
}) async {
  final dir = await getTemporaryDirectory();
  final f = File('${dir.path}/$key${mediaExt(mime, name)}');
  if (!await f.exists() || (await f.length()) != bytes.length) {
    await f.writeAsBytes(bytes, flush: true);
  }
  return MediaHandle(bytes: bytes, path: f.path);
}

ImageProvider imageProviderFor(MediaHandle handle) => FileImage(File(handle.path!));
