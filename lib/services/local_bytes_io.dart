import 'dart:io';
import 'dart:typed_data';

/// Read bytes from a local filesystem path (native only).
Future<Uint8List> readLocalBytes(String path) =>
    File(path).readAsBytes();
