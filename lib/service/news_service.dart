import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shinpo/model/news.dart';
import 'package:shinpo/config/api_config.dart';
import 'package:shinpo/util/date_formatter.dart';

class NewsService {
  Future<List<News>> fetchNewsList(DateTime startDate, DateTime endDate) async {
    if (!_isValidDate(startDate) || !_isValidDate(endDate)) {
      throw Exception('Invalid date provided to API');
    }

    if (startDate.isAfter(endDate)) {
      throw Exception('Start date cannot be after end date');
    }

    final uri = ApiConfig.newsUri(
      startDate: formatDateForApi(startDate),
      endDate: formatDateForApi(endDate),
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
        if (response.statusCode == 500) {
          throw Exception(
              'Server temporarily unavailable. Please try again later.');
        } else if (response.statusCode >= 500) {
          throw Exception(
              'Server error (${response.statusCode}). Please try again later.');
        } else if (response.statusCode >= 400) {
          throw Exception(
              'Request error (${response.statusCode}). Please check your connection.');
        } else {
          throw Exception('Failed to fetch news: HTTP ${response.statusCode}');
        }
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        throw Exception(
            'Network connection failed. Please check your internet connection.');
      } else {
        throw Exception('Failed to fetch news: $e');
      }
    }
  }

  bool _isValidDate(DateTime date) {
    try {
      final now = DateTime.now().toUtc();
      final minDate = DateTime(2020, 1, 1);
      final maxDate = now.add(Duration(days: 365));

      return date.isAfter(minDate) && date.isBefore(maxDate);
    } catch (e) {
      print('NewsService: Date validation error: $e');
      return false;
    }
  }

}
