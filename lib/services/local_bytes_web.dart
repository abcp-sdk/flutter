import 'dart:typed_data';

/// Web has no filesystem paths; picked files always carry in-memory bytes.
Future<Uint8List> readLocalBytes(String path) async =>
    throw UnsupportedError('no local filesystem on web');
