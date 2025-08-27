import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinpo/error_reporter.dart';
import 'package:shinpo/model/news.dart';
import 'package:shinpo/service/cache_manager_service.dart';
import 'package:shinpo/repository/news_repository.dart';
import 'package:shinpo/service/config_service.dart';
import 'package:http/http.dart' as http;

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
      _ref.read(offlineModeProvider.notifier).state = true;
      final cached = await _manager.loadAllCachedNews();
      state = AsyncValue.data(cached);
    }
  }
}

final cacheStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final newsRepo = NewsRepository();
  final configService = ConfigService();

  final all = await newsRepo.getAllNews();
  final articleCount = all.length;

  final config = await configService.getConfig();
  DateTime? lastUpdate;
  if (config != null && config.newsFetchedEndUtc.isNotEmpty) {
    lastUpdate = DateTime.tryParse(config.newsFetchedEndUtc);
  }

  bool hasInternet = false;
  try {
    final uri = Uri(scheme: 'https', host: 'nhk.dekiru.app', path: '/news');
    final res = await http.head(uri).timeout(const Duration(seconds: 3));
    hasInternet = res.statusCode >= 200 && res.statusCode < 400;
  } catch (_) {
    hasInternet = false;
  }
  final initialized = articleCount > 0 || lastUpdate != null;

  return {
    'initialized': initialized,
    'articleCount': articleCount,
    'lastUpdate': lastUpdate,
    'hasInternetConnection': hasInternet,
  };
});
