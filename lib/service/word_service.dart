import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shinpo/model/word.dart';
import 'package:shinpo/config/api_config.dart';

class WordService {
  Future<List<Word>> fetchWordList(String newsId) async {
    final uri = ApiConfig.wordsUri(newsId);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final decoder = Utf8Decoder();
      final wordList = List.of(json.decode(decoder.convert(response.bodyBytes)))
          .map((news) => Word.fromJson(news))
          .toList();

      return wordList;
    } else {
      throw Exception('Failed to fetch words');
    }
  }
}
