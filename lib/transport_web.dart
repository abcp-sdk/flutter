import 'package:connectrpc/connect.dart' as connect;
import 'package:connectrpc/web.dart';

/// Web: fetch-based client; the browser trust store is used, so [caPem] is
/// ignored (kept for signature parity with the native transport).
connect.HttpClient buildAgentHttpClient({String? caPem}) => createHttpClient();

/// Build a bearer-auth Connect interceptor.
connect.Interceptor agentBearerInterceptor(String token) {
  return <I extends Object, O extends Object>(connect.AnyFn<I, O> next) {
    return (req) async {
      req.headers.set('authorization', ['Bearer $token']);
      return next(req);
    };
  };
}
