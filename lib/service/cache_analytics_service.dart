import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class CacheAnalyticsService {
  static const String _hitCountKey = 'cache_hit_count';
  static const String _missCountKey = 'cache_miss_count';
  static const String _lastOptimizationKey = 'last_cache_optimization';
  static const String _totalRequestsKey = 'total_cache_requests';

  Future<void> recordCacheHit() async {
    final prefs = await SharedPreferences.getInstance();
    final currentHits = prefs.getInt(_hitCountKey) ?? 0;
    final currentTotal = prefs.getInt(_totalRequestsKey) ?? 0;
    
    await prefs.setInt(_hitCountKey, currentHits + 1);
    await prefs.setInt(_totalRequestsKey, currentTotal + 1);
  }

  Future<void> recordCacheMiss() async {
    final prefs = await SharedPreferences.getInstance();
    final currentMisses = prefs.getInt(_missCountKey) ?? 0;
    final currentTotal = prefs.getInt(_totalRequestsKey) ?? 0;
    
    await prefs.setInt(_missCountKey, currentMisses + 1);
    await prefs.setInt(_totalRequestsKey, currentTotal + 1);
  }

  Future<void> recordOptimization() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_lastOptimizationKey, now);
  }

  Future<Map<String, dynamic>> getAnalytics() async {
    final prefs = await SharedPreferences.getInstance();
    
    final hits = prefs.getInt(_hitCountKey) ?? 0;
    final misses = prefs.getInt(_missCountKey) ?? 0;
    final total = prefs.getInt(_totalRequestsKey) ?? 0;
    final lastOptimization = prefs.getInt(_lastOptimizationKey);
    
    final hitRate = total > 0 ? (hits / total) * 100 : 0.0;
    
    return {
      'hitCount': hits,
      'missCount': misses,
      'totalRequests': total,
      'hitRate': hitRate,
      'lastOptimization': lastOptimization != null 
          ? DateTime.fromMillisecondsSinceEpoch(lastOptimization)
          : null,
    };
  }

  Future<void> resetAnalytics() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hitCountKey);
    await prefs.remove(_missCountKey);
    await prefs.remove(_totalRequestsKey);
    await prefs.remove(_lastOptimizationKey);
  }

  Future<String> getHitRatePercentage() async {
    final analytics = await getAnalytics();
    final hitRate = analytics['hitRate'] as double;
    return '${hitRate.toStringAsFixed(1)}%';
  }

  Future<bool> shouldOptimize() async {
    final analytics = await getAnalytics();
    final lastOptimization = analytics['lastOptimization'] as DateTime?;
    
    if (lastOptimization == null) {
      return true; 
    }
    
    final daysSinceLastOptimization = DateTime.now().difference(lastOptimization).inDays;
    return daysSinceLastOptimization >= 7; 
  }
}
