import 'package:shared_preferences/shared_preferences.dart';

class BookmarkService {
  static const String _bookmarksKey = 'bookmarked_news_ids';

  Future<List<String>> getBookmarkedNewsIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_bookmarksKey) ?? [];
  }

  Future<bool> addBookmark(String newsId) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = await getBookmarkedNewsIds();

    if (!bookmarks.contains(newsId)) {
      bookmarks.add(newsId);
      return await prefs.setStringList(_bookmarksKey, bookmarks);
    }
    return true;
  }

  Future<bool> removeBookmark(String newsId) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = await getBookmarkedNewsIds();

    bookmarks.remove(newsId);
    return await prefs.setStringList(_bookmarksKey, bookmarks);
  }

  Future<bool> isBookmarked(String newsId) async {
    final bookmarks = await getBookmarkedNewsIds();
    return bookmarks.contains(newsId);
  }

  Future<bool> toggleBookmark(String newsId) async {
    final isBookmarked = await this.isBookmarked(newsId);
    if (isBookmarked) {
      return await removeBookmark(newsId);
    } else {
      return await addBookmark(newsId);
    }
  }
}
