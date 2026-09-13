import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import '../api.dart';

/// Web: download the artifact by opening a browser save. Files are fetched
/// through the agent's GetFile RPC (authenticated bytes), so we materialise a
/// blob and hand it to an anchor download.
class DownloadService {
  DownloadService(this.api);
  final AgentBindApi api;

  Future<String> download({
    required String path,
    required String displayName,
    String mimeType = 'application/octet-stream',
    void Function(int received, int total)? onProgress,
  }) async {
    final bytes = await api.fetchFileBytes(path);
    final blob = web.Blob(
      [Uint8List.fromList(bytes).toJS].toJS,
      web.BlobPropertyBag(type: mimeType),
    );
    final url = web.URL.createObjectURL(blob);
    final a = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..download = displayName;
    a.click();
    web.URL.revokeObjectURL(url);
    return displayName;
  }
}
