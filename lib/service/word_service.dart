import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shinpo/model/word.dart';
import 'package:shinpo/config/api_config.dart';
import 'package:shinpo/service/http_service.dart';

class WordService {
  Future<List<Word>> fetchWordList(String newsId) async {
    final uri = ApiConfig.wordsUri(newsId);
    try {
      final response = await HttpService.get(uri, timeout: const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoder = Utf8Decoder();
        final wordList = List.of(json.decode(decoder.convert(response.bodyBytes)))
            .map((news) => Word.fromJson(news))
            .toList();

        return wordList;
      } else {
        throw Exception('Failed to fetch words: HTTP ${response.statusCode}');
      }
    } on SocketException catch (_) {
      throw Exception('Network connection failed. Please check your internet connection.');
    } on TimeoutException catch (_) {
      throw Exception('Network connection failed. Please check your internet connection.');
    } on http.ClientException catch (e) {
      throw Exception('Request error: ${e.message}');
    }
  }
}
