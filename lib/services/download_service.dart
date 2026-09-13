/// Conditional export: native (dart:io + Android MethodChannel) vs web
/// (browser download of the artifact URL).
export 'download_service_io.dart'
    if (dart.library.js_interop) 'download_service_web.dart';
