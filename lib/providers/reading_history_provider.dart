import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:shinpo/model/news.dart';

class ReadingHistoryItem {
  final String newsId;
  final String title;
  final DateTime readAt;
  final int readProgress;
  ReadingHistoryItem({
    required this.newsId,
    required this.title,
    required this.readAt,
    this.readProgress = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'newsId': newsId,
      'title': title,
      'readAt': readAt.toIso8601String(),
      'readProgress': readProgress,
    };
  }

  factory ReadingHistoryItem.fromJson(Map<String, dynamic> json) {
    return ReadingHistoryItem(
      newsId: json['newsId'],
      title: json['title'],
      readAt: DateTime.parse(json['readAt']),
      readProgress: json['readProgress'] ?? 0,
    );
  }
}

class ReadingHistoryNotifier extends StateNotifier<List<ReadingHistoryItem>> {
  ReadingHistoryNotifier() : super([]) {
    _loadHistory();
  }

  static const String _historyKey = 'reading_history';
  static const int _maxHistoryItems = 100;

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);

      if (historyJson != null) {
        final List<dynamic> historyList = jsonDecode(historyJson);
        state = historyList
            .map((item) => ReadingHistoryItem.fromJson(item))
            .toList();
      }
    } catch (e) {
      state = [];
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = jsonEncode(
        state.map((item) => item.toJson()).toList(),
      );
      await prefs.setString(_historyKey, historyJson);
    } catch (e) {}
  }

  Future<void> addToHistory(News news, {int readProgress = 0}) async {
    final existingIndex = state.indexWhere(
      (item) => item.newsId == news.newsId,
    );

    final newItem = ReadingHistoryItem(
      newsId: news.newsId,
      title: news.title,
      readAt: DateTime.now(),
      readProgress: readProgress,
    );

    if (existingIndex != -1) {
      final updatedList = [...state];
      updatedList[existingIndex] = newItem;
      updatedList.removeAt(existingIndex);
      updatedList.insert(0, newItem);
      state = updatedList;
    } else {
      state = [newItem, ...state];

      if (state.length > _maxHistoryItems) {
        state = state.take(_maxHistoryItems).toList();
      }
    }

    await _saveHistory();
  }

  Future<void> updateReadProgress(String newsId, int progress) async {
    final index = state.indexWhere((item) => item.newsId == newsId);
    if (index != -1) {
      final updatedList = [...state];
      updatedList[index] = ReadingHistoryItem(
        newsId: updatedList[index].newsId,
        title: updatedList[index].title,
        readAt: DateTime.now(),
        readProgress: progress,
      );
      state = updatedList;
      await _saveHistory();
    }
  }

  Future<void> clearHistory() async {
    state = [];
    await _saveHistory();
  }

  ReadingHistoryItem? getHistoryForNews(String newsId) {
    try {
      return state.firstWhere((item) => item.newsId == newsId);
    } catch (e) {
      return null;
    }
  }
}

final readingHistoryProvider =
    StateNotifierProvider<ReadingHistoryNotifier, List<ReadingHistoryItem>>(
      (ref) => ReadingHistoryNotifier(),
    );
