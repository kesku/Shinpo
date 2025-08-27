import 'dart:async';

import 'package:shinpo/model/news.dart';
import 'package:shinpo/repository/news_repository.dart';
import 'package:shinpo/service/cached_news_service.dart';
import 'package:shinpo/service/config_service.dart';
import 'package:shinpo/service/cache_analytics_service.dart';

class CacheManagerService {
  final _cachedNewsService = CachedNewsService();
  final _newsRepository = NewsRepository();
  final _configService = ConfigService();
  final _analyticsService = CacheAnalyticsService();

  Future<List<News>>? _inFlightRefresh;

  
  static const int defaultCacheDays = 14;
  static const int maxCacheDays = 30;
  static const int minCacheDays = 7;

  Future<List<News>> refreshCache({int days = defaultCacheDays}) async {
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

    
    final now = DateTime.now().toUtc();
    if (newestDate.isAfter(now)) {
      newestDate = now.subtract(Duration(days: days));
    }

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

    
    if (endDate.isAfter(now)) {
      endDate = now;
    }

    
    if (!_isValidDate(startDate) || !_isValidDate(endDate)) {
      print('CacheManagerService: Invalid date detected, returning cached data');
      return currentNews;
    }

    
    if (startDate.isAfter(endDate)) {
      print('CacheManagerService: Invalid date range, returning cached data');
      return currentNews;
    }
    
    final result = await _cachedNewsService.fetchNewsList(startDate, endDate);
    
    
    if (result.isEmpty && currentNews.isNotEmpty) {
      return currentNews;
    }
    
    return result;
  }

  Future<List<News>> loadAllCachedNews() async {
    final all = await _newsRepository.getAllNews();
    all.sort((a, b) => -a.publishedAtUtc.compareTo(b.publishedAtUtc));
    return all;
  }

  
  bool _isValidDate(DateTime date) {
    try {
      
      final now = DateTime.now().toUtc();
      final minDate = DateTime(2020, 1, 1); 
      final maxDate = now.add(Duration(days: 365)); 
      
      return date.isAfter(minDate) && date.isBefore(maxDate);
    } catch (e) {
      print('CacheManagerService: Date validation error: $e');
      return false;
    }
  }

  bool _isValidDateString(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return _isValidDate(date);
    } catch (e) {
      print('CacheManagerService: Invalid date string: $dateString');
      return false;
    }
  }

  
  Future<void> cleanupOldCache({int maxDays = defaultCacheDays}) async {
    try {
      await _newsRepository.deleteNewsOlderThanDays(maxDays);
    } catch (e) {
      
      print('Cache cleanup failed: $e');
    }
  }

  Future<void> clearAllCache() async {
    try {
      await _newsRepository.clearAllNews();
      await _configService.clearConfig();
      await _analyticsService.resetAnalytics();
    } catch (e) {
      print('Cache clear failed: $e');
      rethrow;
    }
  }

  Future<bool> validateCache() async {
    try {
      final allNews = await _newsRepository.getAllNews();
      
      
      if (allNews.isEmpty) {
        return true; 
      }

      
      for (final news in allNews) {
        if (news.newsId.isEmpty || 
            news.title.isEmpty || 
            news.publishedAtUtc.isEmpty ||
            news.publishedAtEpoch == 0) {
          return false; 
        }
        
        
        if (!_isValidDateString(news.publishedAtUtc)) {
          print('CacheManagerService: Invalid date found in cache: ${news.publishedAtUtc}');
          return false;
        }
      }

      return true;
    } catch (e) {
      print('Cache validation failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final size = await _newsRepository.getCacheSize();
      final oldestDate = await _newsRepository.getOldestArticleDate();
      final newestDate = await _newsRepository.getNewestArticleDate();
      final isValid = await validateCache();
      final analytics = await _analyticsService.getAnalytics();

      return {
        'size': size,
        'oldestDate': oldestDate,
        'newestDate': newestDate,
        'isValid': isValid,
        'ageInDays': newestDate != null 
            ? DateTime.now().difference(newestDate).inDays 
            : null,
        'hitRate': analytics['hitRate'],
        'totalRequests': analytics['totalRequests'],
        'lastOptimization': analytics['lastOptimization'],
      };
    } catch (e) {
      print('Failed to get cache stats: $e');
      return {
        'size': 0,
        'oldestDate': null,
        'newestDate': null,
        'isValid': false,
        'ageInDays': null,
        'hitRate': 0.0,
        'totalRequests': 0,
        'lastOptimization': null,
      };
    }
  }

  Future<void> warmCache({int days = 7}) async {
    try {
      
      await refreshCache(days: days);
    } catch (e) {
      print('Cache warming failed: $e');
      
    }
  }

  Future<void> optimizeCache() async {
    try {
      
      await cleanupOldCache(maxDays: defaultCacheDays);
      
      
      final isValid = await validateCache();
      if (!isValid) {
        print('Cache validation failed, clearing cache');
        await clearAllCache();
      }
      
      
      await _analyticsService.recordOptimization();
    } catch (e) {
      print('Cache optimization failed: $e');
    }
  }

  
  Future<void> recordCacheHit() async {
    await _analyticsService.recordCacheHit();
  }

  Future<void> recordCacheMiss() async {
    await _analyticsService.recordCacheMiss();
  }

  Future<Map<String, dynamic>> getAnalytics() async {
    return await _analyticsService.getAnalytics();
  }

  Future<bool> shouldOptimize() async {
    return await _analyticsService.shouldOptimize();
  }
}
