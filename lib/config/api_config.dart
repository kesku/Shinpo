class ApiConfig {
  ApiConfig._();

  static const String scheme = 'https';
  static const String host = 'nhk.dekiru.app';

  static Uri newsUri({required String startDate, required String endDate}) {
    return Uri(
      scheme: scheme,
      host: host,
      path: 'news',
      queryParameters: {
        'startDate': startDate,
        'endDate': endDate,
      },
    );
  }

  static Uri wordsUri(String newsId) {
    return Uri(
      scheme: scheme,
      host: host,
      path: 'words',
      queryParameters: {
        'newsId': newsId,
      },
    );
  }
}

