import 'package:http/http.dart' as http;

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
        final response = await http.head(uri).timeout(const Duration(seconds: 3));
        if (response.statusCode >= 200 && response.statusCode < 400) {
          return true; 
        }
      } catch (e) {
        
        continue;
      }
    }
    return false; 
  }

  static Future<bool> isNhkServerReachable() async {
    try {
      final uri = Uri(
        scheme: 'https', 
        host: 'nhk.dekiru.app', 
        path: '/news',
        queryParameters: {
          'startDate': DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
          'endDate': DateTime.now().toIso8601String(),
        },
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      
      
      return true;
    } catch (e) {
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
