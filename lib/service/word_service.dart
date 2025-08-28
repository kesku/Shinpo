import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shinpo/model/word.dart';
import 'package:shinpo/config/api_config.dart';
import 'package:shinpo/service/http_service.dart';
import 'package:shinpo/repository/word_repository.dart';

class WordService {
  final _repo = WordRepository();

  Future<List<Word>> fetchWordList(String newsId,
      {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      try {
        final cached = await _repo.getWords(newsId);
        if (cached.isNotEmpty) {
          return cached;
        }
      } catch (_) {}
    }

    final uri = ApiConfig.wordsUri(newsId);
    try {
      final response =
          await HttpService.get(uri, timeout: const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoder = Utf8Decoder();
        final wordList =
            List.of(json.decode(decoder.convert(response.bodyBytes)))
                .map((news) => Word.fromJson(news))
                .toList();

        try {
          await _repo.saveWords(newsId, wordList);
        } catch (_) {}
        return wordList;
      } else {
        throw Exception('Failed to fetch words: HTTP ${response.statusCode}');
      }
    } on SocketException catch (_) {
      final cached = await _repo.getWords(newsId);
      if (cached.isNotEmpty) return cached;
      throw Exception(
          'Network connection failed. Please check your internet connection.');
    } on TimeoutException catch (_) {
      final cached = await _repo.getWords(newsId);
      if (cached.isNotEmpty) return cached;
      throw Exception(
          'Network connection failed. Please check your internet connection.');
    } on http.ClientException catch (e) {
      throw Exception('Request error: ${e.message}');
    }
  }
}
