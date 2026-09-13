import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'attachment_mime.dart';
import 'clipboard_media_types.dart';

/// Web: the DOM `paste` listener (installed by [installWebPasteListener])
/// handles clipboard files directly; this async reader is unused.
Future<ClipboardMedia?> readClipboardMedia() async => null;

/// Install a document-level `paste` listener so a pasted image/file becomes an
/// attachment. A page cannot read arbitrary clipboard *files* through the
/// async Clipboard API, but a `paste` event's `clipboardData.files` does expose
/// them (the browser grants access for the duration of the event).
///
/// [onMedia] is invoked once per pasted file. Returns a disposer.
void Function() installWebPasteListener(
  void Function(ClipboardMedia media) onMedia,
) {
  void handler(web.Event event) {
    final ce = event as web.ClipboardEvent;
    final files = ce.clipboardData?.files;
    if (files == null || files.length == 0) return;
    // Image first, then any other file, per product preference.
    final ordered = <web.File>[
      for (var i = 0; i < files.length; i++)
        if (files.item(i)!.type.startsWith('image/')) files.item(i)!,
      for (var i = 0; i < files.length; i++)
        if (!files.item(i)!.type.startsWith('image/')) files.item(i)!,
    ];
    for (final file in ordered) {
      _readFile(file, onMedia);
    }
  }

  web.document.addEventListener('paste', handler.toJS);
  return () => web.document.removeEventListener('paste', handler.toJS);
}

Future<void> _readFile(
  web.File file,
  void Function(ClipboardMedia) onMedia,
) async {
  final reader = web.FileReader();
  final done = reader.onLoadEnd.first.then((_) => reader.result);
  reader.readAsArrayBuffer(file);
  final result = await done;
  final buffer = (result as JSArrayBuffer?)?.toDart;
  if (buffer == null) return;
  final bytes = buffer.asUint8List();
  if (bytes.isEmpty) return;
  final name = file.name.isNotEmpty
      ? file.name
      : 'image-${DateTime.now().millisecondsSinceEpoch}.png';
  onMedia(ClipboardMedia(
    bytes: bytes,
    name: name,
    mime: file.type.isNotEmpty ? file.type : mimeOfName(name),
  ));
}
