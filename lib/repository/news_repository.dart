import 'package:shinpo/model/news.dart';
import 'package:sembast/sembast.dart';

import 'base_repository.dart';

class NewsRepository extends BaseRepository {
  final _newsStore = stringMapStoreFactory.store('news');

  Future<List<News>> getNews(DateTime startDate, DateTime endDate) async {
    final database = await getDatabase();
    final finder = Finder(
        filter: Filter.and([
      Filter.greaterThanOrEquals(
          'publishedAtEpoch', startDate.millisecondsSinceEpoch),
      Filter.lessThanOrEquals(
          'publishedAtEpoch', endDate.millisecondsSinceEpoch)
    ]));

    final rows = await _newsStore.find(database, finder: finder);

    return rows.map((n) {
      return News.fromJson(n.value);
    }).toList();
  }

  Future<void> saveAll(List<News> news) async {
    final database = await getDatabase();

    await Future.wait(news.map((n) async {
      await _newsStore.record(n.newsId).put(database, n.toMap());
    }));
  }

  Future<List<News>> getAllNews() async {
    final database = await getDatabase();
    final rows = await _newsStore.find(database);

    return rows.map((n) {
      return News.fromJson(n.value);
    }).toList();
  }

  Future<News?> getNewsById(String newsId) async {
    final database = await getDatabase();
    final record = await _newsStore.record(newsId).get(database);

    if (record != null) {
      return News.fromJson(record);
    }
    return null;
  }

  
  Future<void> deleteNewsBefore(DateTime cutoffDate) async {
    final database = await getDatabase();
    final finder = Finder(
      filter: Filter.lessThan(
        'publishedAtEpoch',
        cutoffDate.millisecondsSinceEpoch,
      ),
    );
    
    await _newsStore.delete(database, finder: finder);
  }

  Future<void> deleteNewsOlderThanDays(int days) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    await deleteNewsBefore(cutoffDate);
  }

  Future<int> getCacheSize() async {
    final database = await getDatabase();
    final count = await _newsStore.count(database);
    return count;
  }

  Future<DateTime?> getOldestArticleDate() async {
    final database = await getDatabase();
    final finder = Finder(
      sortOrders: [SortOrder('publishedAtEpoch')],
    );
    
    final records = await _newsStore.find(database, finder: finder);
    if (records.isNotEmpty) {
      final news = News.fromJson(records.first.value);
      return DateTime.fromMillisecondsSinceEpoch(news.publishedAtEpoch);
    }
    return null;
  }

  Future<DateTime?> getNewestArticleDate() async {
    final database = await getDatabase();
    final finder = Finder(
      sortOrders: [SortOrder('publishedAtEpoch', false)], 
    );
    
    final records = await _newsStore.find(database, finder: finder);
    if (records.isNotEmpty) {
      final news = News.fromJson(records.first.value);
      return DateTime.fromMillisecondsSinceEpoch(news.publishedAtEpoch);
    }
    return null;
  }

  Future<void> clearAllNews() async {
    final database = await getDatabase();
    await _newsStore.delete(database);
  }
}
