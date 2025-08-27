import 'package:shinpo/util/date_validation.dart';

class News {
  String newsId = '';

  String title = '';

  String titleWithRuby = '';

  String body = '';

  String imageUrl = '';

  String publishedAtUtc = '';

  int publishedAtEpoch = 0;

  String m3u8Url = '';

  News();

  factory News.fromJson(Map<String, dynamic> json) {
    final news = News();
    news.newsId = json['newsId'];
    news.title = json['title'];
    news.titleWithRuby = json['titleWithRuby'];
    news.body = json['body'];
    news.imageUrl = json['imageUrl'];
    news.publishedAtUtc = json['publishedAtUtc'];

    try {
      final date = DateTime.parse(news.publishedAtUtc);
      news.publishedAtEpoch = date.millisecondsSinceEpoch;
    } catch (e) {
      print('News.fromJson: Invalid date format: ${news.publishedAtUtc}');

      news.publishedAtEpoch = 0;
    }

    news.m3u8Url = json['m3u8Url'];

    return news;
  }

  Map<String, dynamic> toMap() {
    return {
      'newsId': newsId,
      'title': title,
      'titleWithRuby': titleWithRuby,
      'body': body,
      'imageUrl': imageUrl,
      'publishedAtUtc': publishedAtUtc,
      'publishedAtEpoch': publishedAtEpoch,
      'm3u8Url': m3u8Url
    };
  }

  bool isValid() {
    return newsId.isNotEmpty &&
        title.isNotEmpty &&
        publishedAtUtc.isNotEmpty &&
        publishedAtEpoch > 0 &&
        DateValidation.isValidDateString(publishedAtUtc);
  }
}
