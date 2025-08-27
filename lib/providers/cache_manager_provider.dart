import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinpo/error_reporter.dart';
import 'package:shinpo/model/news.dart';
import 'package:shinpo/service/cache_manager_service.dart';
import 'package:shinpo/repository/news_repository.dart';
import 'package:shinpo/service/config_service.dart';
import 'package:shinpo/service/connectivity_service.dart';

final cacheManagerServiceProvider = Provider<CacheManagerService>((ref) {
  return CacheManagerService();
});

final cacheInitializationProvider = FutureProvider<List<News>>((ref) async {
  final manager = ref.read(cacheManagerServiceProvider);

  final cached = await manager.loadAllCachedNews();
  if (cached.isNotEmpty) {
    ref.read(offlineModeProvider.notifier).state = false;
    return cached;
  }

  try {
    final news = await manager.refreshCache();
    ref.read(offlineModeProvider.notifier).state = false;
    return news;
  } catch (e) {
    ref.read(offlineModeProvider.notifier).state = true;
    return [];
  }
});

final offlineModeProvider = StateProvider<bool>((ref) => false);

final cachedNewsProvider =
    StateNotifierProvider<CachedNewsNotifier, AsyncValue<List<News>>>((ref) {
      final manager = ref.read(cacheManagerServiceProvider);
      return CachedNewsNotifier(manager, ref);
    });

class CachedNewsNotifier extends StateNotifier<AsyncValue<List<News>>> {
  CachedNewsNotifier(this._manager, this._ref)
    : super(const AsyncValue.loading());

  final CacheManagerService _manager;
  final Ref _ref;

  Future<void> loadAllCachedNews() async {
    try {
      state = const AsyncValue.loading();
      final news = await _manager.loadAllCachedNews();
      state = AsyncValue.data(news);
    } catch (e, st) {
      ErrorReporter.reportError(e, st);
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refreshCache({int days = 14}) async {
    try {
      final news = await _manager.refreshCache(days: days);
      _ref.read(offlineModeProvider.notifier).state = false;
      state = AsyncValue.data(news);
    } catch (e, st) {
      ErrorReporter.reportError(e, st);
      
      
      final errorString = e.toString();
      if (errorString.contains('Network connection failed') || 
          errorString.contains('SocketException') ||
          errorString.contains('TimeoutException')) {
        _ref.read(offlineModeProvider.notifier).state = true;
      } else {
        
        _ref.read(offlineModeProvider.notifier).state = false;
      }
      
      
      try {
        final cached = await _manager.loadAllCachedNews();
        if (cached.isNotEmpty) {
          state = AsyncValue.data(cached);
        } else {
          
          state = AsyncValue.error(e, st);
        }
      } catch (fallbackError, fallbackStack) {
        ErrorReporter.reportError(fallbackError, fallbackStack);
        
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> clearCache() async {
    try {
      await _manager.clearAllCache();
      state = const AsyncValue.data([]);
      _ref.read(offlineModeProvider.notifier).state = true;
    } catch (e, st) {
      ErrorReporter.reportError(e, st);
      rethrow;
    }
  }

  Future<void> optimizeCache() async {
    try {
      await _manager.optimizeCache();
      
      await loadAllCachedNews();
    } catch (e, st) {
      ErrorReporter.reportError(e, st);
    }
  }

  Future<void> warmCache({int days = 7}) async {
    try {
      await _manager.warmCache(days: days);
    } catch (e, st) {
      ErrorReporter.reportError(e, st);
    }
  }
}

final cacheStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final newsRepo = NewsRepository();
  final configService = ConfigService();
  final cacheManager = ref.read(cacheManagerServiceProvider);

  final all = await newsRepo.getAllNews();
  final articleCount = all.length;

  final config = await configService.getConfig();
  DateTime? lastUpdate;
  if (config != null && config.newsFetchedEndUtc.isNotEmpty) {
    lastUpdate = DateTime.tryParse(config.newsFetchedEndUtc);
  }

  final connectivityStatus = await ConnectivityService.getConnectivityStatus();
  final hasInternet = connectivityStatus['hasInternet'] ?? false;
  final nhkServerReachable = connectivityStatus['nhkServerReachable'] ?? false;
  
  final initialized = articleCount > 0 || lastUpdate != null;

  
  final cacheStats = await cacheManager.getCacheStats();

  return {
    'initialized': initialized,
    'articleCount': articleCount,
    'lastUpdate': lastUpdate,
    'hasInternetConnection': hasInternet,
    'nhkServerReachable': nhkServerReachable,
    'cacheSize': cacheStats['size'],
    'oldestDate': cacheStats['oldestDate'],
    'newestDate': cacheStats['newestDate'],
    'isValid': cacheStats['isValid'],
    'ageInDays': cacheStats['ageInDays'],
  };
});


final cacheStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final cacheManager = ref.read(cacheManagerServiceProvider);
  return await cacheManager.getCacheStats();
});

final cacheValidationProvider = FutureProvider<bool>((ref) async {
  final cacheManager = ref.read(cacheManagerServiceProvider);
  return await cacheManager.validateCache();
});

final cacheOptimizationProvider = FutureProvider<void>((ref) async {
  final cacheManager = ref.read(cacheManagerServiceProvider);
  await cacheManager.optimizeCache();
});
