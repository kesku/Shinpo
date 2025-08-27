import 'dart:async';

import 'package:shinpo/model/news.dart';
import 'package:shinpo/repository/news_repository.dart';
import 'package:shinpo/service/cached_news_service.dart';
import 'package:shinpo/service/config_service.dart';

class CacheManagerService {
  final _cachedNewsService = CachedNewsService();
  final _newsRepository = NewsRepository();
  final _configService = ConfigService();

  Future<List<News>>? _inFlightRefresh;

  Future<List<News>> refreshCache({int days = 14}) async {
    if (_inFlightRefresh != null) {
      return _inFlightRefresh!;
    }

    final future = _performSmartRefresh(days).whenComplete(() {
      _inFlightRefresh = null;
    });

    _inFlightRefresh = future;
    return future;
  }

  Future<List<News>> _performSmartRefresh(int days) async {
    final currentNews = await loadAllCachedNews();
    final config = await _configService.getConfig();

    final latestNews = currentNews.isEmpty ? null : currentNews.first;
    final useConfigDate = config != null && latestNews == null;

    DateTime newestDate = latestNews == null
        ? (config != null
                  ? DateTime.parse(config.newsFetchedEndUtc)
                  : DateTime.now().toUtc())
              .subtract(Duration(days: days))
        : DateTime.parse(latestNews.publishedAtUtc).add(Duration(days: 1));

    DateTime startDate = DateTime.utc(
      newestDate.year,
      newestDate.month,
      newestDate.day,
      0,
      0,
      0,
    );

    DateTime endDate = useConfigDate
        ? DateTime.parse(config.newsFetchedEndUtc)
        : DateTime.utc(
            newestDate.year,
            newestDate.month,
            newestDate.day,
            23,
            59,
            59,
          ).add(Duration(days: days));

    return await _cachedNewsService.fetchNewsList(startDate, endDate);
  }

  Future<List<News>> loadAllCachedNews() async {
    final all = await _newsRepository.getAllNews();
    all.sort((a, b) => -a.publishedAtUtc.compareTo(b.publishedAtUtc));
    return all;
  }
}
