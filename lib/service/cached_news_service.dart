import 'package:shinpo/error_reporter.dart';
import 'package:shinpo/model/config.dart';
import 'package:shinpo/model/news.dart';
import 'package:shinpo/repository/config_repository.dart';
import 'package:shinpo/repository/news_repository.dart';
import 'package:shinpo/service/config_service.dart';
import 'package:shinpo/service/news_service.dart';

class CachedNewsService {
  final _configRepository = ConfigRepository();
  final _newsRepository = NewsRepository();
  final _configService = ConfigService();
  final _newsService = NewsService();

  Future<List<News>> fetchNewsList(DateTime startDate, DateTime endDate) async {
    final config = await _configService.getConfig();

    if (config != null && (_newsCached(config, startDate, endDate))) {
      try {
        final news = await _newsRepository.getNews(startDate, endDate);

        news.sort((a, b) => -a.publishedAtUtc.compareTo(b.publishedAtUtc));

        return news;
      } catch (error, stackTrace) {
        ErrorReporter.reportError(error, stackTrace);

        return _newsService.fetchNewsList(startDate, endDate);
      }
    } else {
      final news = await _newsService.fetchNewsList(startDate, endDate);

      if (news.length == 0) {
        return [];
      }

      final newsFetchedStartUtc = news.last.publishedAtUtc;
      final newsFetchedEndUtc = news.first.publishedAtUtc;
      final newConfig = _createNewConfig(
        config,
        newsFetchedStartUtc,
        newsFetchedEndUtc,
      );

      return Future.wait([
        _newsRepository.saveAll(news),
        _configRepository.save(newConfig),
      ]).then((value) => news).catchError((error, stackTrace) {
        ErrorReporter.reportError(error, stackTrace);
        return news;
      });
    }
  }

  bool _newsCached(Config config, DateTime startDate, DateTime endDate) {
    final newsFetchedStartDate = DateTime.parse(config.newsFetchedStartUtc);
    final newsFetchedEndDate = DateTime.parse(config.newsFetchedEndUtc);

    return newsFetchedStartDate.compareTo(startDate) <= 0 &&
        newsFetchedEndDate.compareTo(endDate) >= 0;
  }

  Config _createNewConfig(
    Config? config,
    String newsFetchedStartUtc,
    String newsFetchedEndUtc,
  ) {
    if (config != null) {
      final newsFetchedStartUtcNew = DateTime.parse(
                newsFetchedStartUtc,
              ).compareTo(DateTime.parse(config.newsFetchedStartUtc)) <=
              0
          ? newsFetchedStartUtc
          : config.newsFetchedStartUtc;
      final newsFetchedEndUtcNew = DateTime.parse(
                newsFetchedEndUtc,
              ).compareTo(DateTime.parse(config.newsFetchedEndUtc)) >=
              0
          ? newsFetchedEndUtc
          : config.newsFetchedEndUtc;

      return Config(
        id: config.id,
        newsFetchedStartUtc: newsFetchedStartUtcNew,
        newsFetchedEndUtc: newsFetchedEndUtcNew,
      );
    } else {
      return Config(
        id: 1,
        newsFetchedStartUtc: newsFetchedStartUtc,
        newsFetchedEndUtc: newsFetchedEndUtc,
      );
    }
  }

  Future<List<News>> getAllNews() async {
    try {
      return await _newsRepository.getAllNews();
    } catch (error, stackTrace) {
      ErrorReporter.reportError(error, stackTrace);
      return [];
    }
  }

  Future<News?> getNewsById(String newsId) async {
    try {
      return await _newsRepository.getNewsById(newsId);
    } catch (error, stackTrace) {
      ErrorReporter.reportError(error, stackTrace);
      return null;
    }
  }
}
