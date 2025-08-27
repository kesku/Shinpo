import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shinpo/config/api_config.dart';
import 'package:shinpo/util/date_formatter.dart';
import 'package:shinpo/service/http_service.dart';

class ConnectivityService {
  static const List<String> _testUrls = [
    'https://www.google.com',
    'https://www.cloudflare.com',
    'https://www.apple.com',
  ];

  static Future<bool> hasInternetConnection() async {
    for (final url in _testUrls) {
      try {
        final uri = Uri.parse(url);
        final response = await HttpService.head(uri, timeout: const Duration(seconds: 3));
        if (response.statusCode >= 200 && response.statusCode < 400) {
          return true;
        }
      } catch (_) {
        continue;
      }
    }
    return false;
  }

  static Future<bool> isNhkServerReachable() async {
    try {
      final now = DateTime.now();
      final uri = ApiConfig.newsUri(
        startDate: formatDateForApi(now.subtract(const Duration(days: 1))),
        endDate: formatDateForApi(now),
      );
      final response = await HttpService.get(uri, timeout: const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 400) {
        return true;
      }
      return false;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } on http.ClientException catch (_) {
      return false;
    }
  }

  static Future<Map<String, bool>> getConnectivityStatus() async {
    final hasInternet = await hasInternetConnection();
    final nhkReachable = hasInternet ? await isNhkServerReachable() : false;

    return {
      'hasInternet': hasInternet,
      'nhkServerReachable': nhkReachable,
    };
  }
}
