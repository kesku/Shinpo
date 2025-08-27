import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shinpo/model/news.dart';
import 'package:shinpo/config/api_config.dart';
import 'package:shinpo/util/date_formatter.dart';
import 'package:shinpo/service/http_service.dart';
import 'package:shinpo/util/date_validation.dart';

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
      final response = await HttpService.get(uri, timeout: const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final decoder = Utf8Decoder();
        final responseBody = decoder.convert(response.bodyBytes);

        final newsList = List.of(
          json.decode(responseBody),
        ).map((news) => News.fromJson(news)).toList();

        newsList.sort((a, b) => b.publishedAtEpoch.compareTo(a.publishedAtEpoch));

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
    } on SocketException catch (_) {
      throw Exception('Network connection failed. Please check your internet connection.');
    } on TimeoutException catch (_) {
      throw Exception('Network connection failed. Please check your internet connection.');
    } on http.ClientException catch (e) {
      throw Exception('Request error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch news: $e');
    }
  }

  bool _isValidDate(DateTime date) {
    return DateValidation.isValidDate(date);
  }

}
