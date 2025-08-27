import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinpo/service/bookmark_service.dart';

final bookmarkServiceProvider = Provider<BookmarkService>((ref) {
  return BookmarkService();
});

final bookmarkedNewsIdsProvider =
    StateNotifierProvider<BookmarkedNewsIdsNotifier, List<String>>((ref) {
  final bookmarkService = ref.watch(bookmarkServiceProvider);
  return BookmarkedNewsIdsNotifier(bookmarkService);
});

class BookmarkedNewsIdsNotifier extends StateNotifier<List<String>> {
  final BookmarkService _bookmarkService;

  BookmarkedNewsIdsNotifier(this._bookmarkService) : super([]) {
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final bookmarks = await _bookmarkService.getBookmarkedNewsIds();
    state = bookmarks;
  }

  Future<void> addBookmark(String newsId) async {
    await _bookmarkService.addBookmark(newsId);
    await _loadBookmarks();
  }

  Future<void> removeBookmark(String newsId) async {
    await _bookmarkService.removeBookmark(newsId);
    await _loadBookmarks();
  }

  Future<void> toggleBookmark(String newsId) async {
    await _bookmarkService.toggleBookmark(newsId);
    await _loadBookmarks();
  }

  bool isBookmarked(String newsId) {
    return state.contains(newsId);
  }
}
