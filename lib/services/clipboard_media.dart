// Platform facade for clipboard media (paste) support.
//
// Native (io): reads images/files from the system clipboard via `pasteboard`.
// Web: installs a DOM `paste` listener (the async Clipboard API does not
// expose arbitrary files to pages).
export 'clipboard_media_types.dart';

import 'clipboard_media_types.dart';
import 'clipboard_media_io.dart'
    if (dart.library.js_interop) 'clipboard_media_web.dart' as impl;

/// Read an image (preferred) or a single file from the system clipboard.
/// Returns `null` when the clipboard holds neither. On web this always
/// returns `null` — use [installWebPasteListener] instead.
Future<ClipboardMedia?> readClipboardMedia() => impl.readClipboardMedia();

/// Install a document-level `paste` listener (web) that yields each pasted
/// image/file through [onMedia]. Returns a disposer. No-op on native.
void Function() installWebPasteListener(
  void Function(ClipboardMedia media) onMedia,
) =>
    impl.installWebPasteListener(onMedia);
