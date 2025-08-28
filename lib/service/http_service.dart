import 'dart:async';
import 'package:http/http.dart' as http;

class HttpService {
  HttpService._();

  static final http.Client client = http.Client();

  static Future<http.Response> get(
    Uri uri, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 10),
  }) {
    return client.get(uri, headers: headers).timeout(timeout);
  }

  static Future<http.Response> head(
    Uri uri, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 5),
  }) {
    return client.head(uri, headers: headers).timeout(timeout);
  }

  static Future<void> close() async {
    client.close();
  }
}
