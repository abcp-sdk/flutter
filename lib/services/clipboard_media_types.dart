import 'dart:typed_data';

/// A clipboard media item (pasted image or file): the bytes plus a display
/// name and concrete mime so it can flow through the normal attachment upload
/// path (`file:<code>`).
class ClipboardMedia {
  final Uint8List bytes;
  final String name;
  final String mime;
  ClipboardMedia({required this.bytes, required this.name, required this.mime});
}
