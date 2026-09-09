import 'package:http/http.dart' as http;

/// Web build: no bundled CA handling, use the default client.
Future<http.Client> platformHttpClient() async => http.Client();