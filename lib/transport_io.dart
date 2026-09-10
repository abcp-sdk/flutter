import 'dart:convert';
import 'dart:io' as io;

import 'package:connectrpc/connect.dart' as connect;
import 'package:connectrpc/http2.dart';

/// Build the platform HTTP client for a direct agent connection: HTTP/2 over
/// TLS (ALPN `h2`) on native, trusting the bundled self-signed CA.
connect.HttpClient buildAgentHttpClient({String? caPem}) {
  final context = io.SecurityContext(withTrustedRoots: true);
  if (caPem != null && caPem.isNotEmpty) {
    context.setTrustedCertificatesBytes(utf8.encode(caPem));
  }
  return createHttpClient(transport: Http2ClientTransport(context: context));
}

/// Build a bearer-auth Connect interceptor.
connect.Interceptor agentBearerInterceptor(String token) {
  return <I extends Object, O extends Object>(connect.AnyFn<I, O> next) {
    return (req) async {
      req.headers.set('authorization', ['Bearer $token']);
      return next(req);
    };
  };
}
