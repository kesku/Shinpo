import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinpo/model/news.dart';
import 'package:shinpo/service/search_service.dart';

class SearchNotifier extends StateNotifier<SearchState> {
  final SearchService _searchService = SearchService();

  SearchNotifier() : super(SearchState());

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = SearchState();
      return;
    }

    state = state.copyWith(isSearching: true, query: query, error: null);

    try {
      final results = await _searchService.searchNews(query);
      final suggestions = await _searchService.getSearchSuggestions(query);

      state = state.copyWith(
        results: results,
        suggestions: suggestions,
        isSearching: false,
        hasSearched: true,
      );

      _addToRecentSearches(query);
    } catch (e) {
      state = state.copyWith(isSearching: false, error: e.toString());
    }
  }

  Future<void> searchInDateRange(
    String query,
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (query.trim().isEmpty) {
      state = SearchState();
      return;
    }

    state = state.copyWith(isSearching: true, query: query, error: null);

    try {
      final results = await _searchService.searchNewsInDateRange(
        query,
        startDate,
        endDate,
      );

      state = state.copyWith(
        results: results,
        isSearching: false,
        hasSearched: true,
      );

      _addToRecentSearches(query);
    } catch (e) {
      state = state.copyWith(isSearching: false, error: e.toString());
    }
  }

  void clearSearch() {
    state = SearchState();
  }

  void _addToRecentSearches(String query) {
    final recentSearches = List<String>.from(state.recentSearches);

    recentSearches.remove(query);

    recentSearches.insert(0, query);

    if (recentSearches.length > 10) {
      recentSearches.removeRange(10, recentSearches.length);
    }

    state = state.copyWith(recentSearches: recentSearches);
  }

  void removeRecentSearch(String query) {
    final recentSearches = List<String>.from(state.recentSearches);
    recentSearches.remove(query);
    state = state.copyWith(recentSearches: recentSearches);
  }

  void clearRecentSearches() {
    state = state.copyWith(recentSearches: []);
  }
}

class SearchState {
  final List<News> results;
  final List<String> suggestions;
  final List<String> recentSearches;
  final bool isSearching;
  final bool hasSearched;
  final String? query;
  final String? error;

  SearchState({
    this.results = const [],
    this.suggestions = const [],
    this.recentSearches = const [],
    this.isSearching = false,
    this.hasSearched = false,
    this.query,
    this.error,
  });

  SearchState copyWith({
    List<News>? results,
    List<String>? suggestions,
    List<String>? recentSearches,
    bool? isSearching,
    bool? hasSearched,
    String? query,
    String? error,
  }) {
    return SearchState(
      results: results ?? this.results,
      suggestions: suggestions ?? this.suggestions,
      recentSearches: recentSearches ?? this.recentSearches,
      isSearching: isSearching ?? this.isSearching,
      hasSearched: hasSearched ?? this.hasSearched,
      query: query ?? this.query,
      error: error ?? this.error,
    );
  }
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((
  ref,
) {
  return SearchNotifier();
});
