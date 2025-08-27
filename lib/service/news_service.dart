import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shinpo/model/news.dart';

class NewsService {
  Future<List<News>> fetchNewsList(DateTime startDate, DateTime endDate) async {
    final uri = Uri(
      scheme: 'https',
      host: 'nhk.dekiru.app',
      path: 'news',
      queryParameters: {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      },
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final decoder = Utf8Decoder();
        final responseBody = decoder.convert(response.bodyBytes);

        final newsList = List.of(
          json.decode(responseBody),
        ).map((news) => News.fromJson(news)).toList();

        newsList.sort((a, b) => -a.publishedAtUtc.compareTo(b.publishedAtUtc));

        return newsList;
      } else {
        print('HTTP error: ${response.statusCode} - ${response.reasonPhrase}');
        print('Response body: ${response.body}');
        throw Exception('Failed to fetch news: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('Network error: $e');
      throw Exception('Failed to fetch news');
    }
  }
}
