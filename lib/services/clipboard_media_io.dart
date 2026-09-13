import 'dart:io';

import 'package:pasteboard/pasteboard.dart';
import 'package:uuid/uuid.dart';

import 'attachment_mime.dart';
import 'clipboard_media_types.dart';

const _uuid = Uuid();

/// Read an image (preferred) or a single file from the system clipboard.
///
/// * Image: encoded by the platform plugin (PNG on Linux) — named
///   `image-<uuid>.png`.
/// * File: the filesystem path is read into bytes; the original name is kept.
///
/// Multiple copied files: the first file is used (the clipboard may hold a
/// batch, but the attachment flow takes one item per paste).
Future<ClipboardMedia?> readClipboardMedia() async {
  // Image FIRST (per product decision): a copied image wins over text/files.
  try {
    final image = await Pasteboard.image;
    if (image != null && image.isNotEmpty) {
      return ClipboardMedia(
        bytes: image,
        name: 'image-${_uuid.v4()}.png',
        mime: 'image/png',
      );
    }
  } catch (_) {
    // Clipboard image unavailable (e.g. permission / no image) — fall through.
  }
  try {
    final files = await Pasteboard.files();
    for (final path in files) {
      final f = File(path);
      if (!await f.exists()) continue;
      final bytes = await f.readAsBytes();
      if (bytes.isEmpty) continue;
      final name = path.split('/').last;
      return ClipboardMedia(
        bytes: bytes,
        name: name.isEmpty ? 'file-${_uuid.v4()}' : name,
        mime: mimeOfName(name),
      );
    }
  } catch (_) {
    // No files on the clipboard.
  }
  return null;
}

/// Native has no document-level paste listener (keyboard shortcuts drive
/// paste through [readClipboardMedia]); returns a no-op disposer.
void Function() installWebPasteListener(
  void Function(ClipboardMedia media) onMedia,
) =>
    () {};
