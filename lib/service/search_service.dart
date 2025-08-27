import 'package:shinpo/model/news.dart';
import 'package:shinpo/repository/news_repository.dart';

class SearchService {
  final _newsRepository = NewsRepository();

  Future<List<News>> searchNews(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      final allNews = await _newsRepository.getAllNews();

      final filteredNews = allNews.where((news) {
        final searchQuery = query.toLowerCase().trim();
        final title = news.title.toLowerCase();
        final body = news.body.toLowerCase();

        return title.contains(searchQuery) || body.contains(searchQuery);
      }).toList();

      filteredNews.sort((a, b) {
        final queryLower = query.toLowerCase();
        final aTitle = a.title.toLowerCase();
        final bTitle = b.title.toLowerCase();

        final aExactTitle = aTitle == queryLower;
        final bExactTitle = bTitle == queryLower;

        if (aExactTitle && !bExactTitle) return -1;
        if (!aExactTitle && bExactTitle) return 1;

        final aStartsWith = aTitle.startsWith(queryLower);
        final bStartsWith = bTitle.startsWith(queryLower);

        if (aStartsWith && !bStartsWith) return -1;
        if (!aStartsWith && bStartsWith) return 1;

        return DateTime.parse(
          b.publishedAtUtc,
        ).compareTo(DateTime.parse(a.publishedAtUtc));
      });

      return filteredNews;
    } catch (e) {
      return [];
    }
  }

  Future<List<News>> searchNewsInDateRange(
    String query,
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      final newsInRange = await _newsRepository.getNews(startDate, endDate);

      final filteredNews = newsInRange.where((news) {
        final searchQuery = query.toLowerCase().trim();
        final title = news.title.toLowerCase();
        final body = news.body.toLowerCase();

        return title.contains(searchQuery) || body.contains(searchQuery);
      }).toList();

      filteredNews.sort((a, b) {
        final queryLower = query.toLowerCase();
        final aTitle = a.title.toLowerCase();
        final bTitle = b.title.toLowerCase();

        final aExactTitle = aTitle == queryLower;
        final bExactTitle = bTitle == queryLower;

        if (aExactTitle && !bExactTitle) return -1;
        if (!aExactTitle && bExactTitle) return 1;

        return DateTime.parse(
          b.publishedAtUtc,
        ).compareTo(DateTime.parse(a.publishedAtUtc));
      });

      return filteredNews;
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> getSearchSuggestions(String partialQuery) async {
    if (partialQuery.trim().isEmpty) {
      return [];
    }

    try {
      final allNews = await _newsRepository.getAllNews();
      final suggestions = <String>{};

      for (final news in allNews) {
        final title = news.title.toLowerCase();
        final query = partialQuery.toLowerCase();

        if (title.contains(query)) {
          final index = title.indexOf(query);
          final suggestion = news.title.substring(
            index,
            index + query.length + 20,
          );
          if (suggestion.length > query.length) {
            suggestions.add(suggestion);
          }
        }
      }

      return suggestions.take(5).toList();
    } catch (e) {
      return [];
    }
  }
}
