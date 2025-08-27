import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FuriganaNotifier extends StateNotifier<bool> {
  FuriganaNotifier() : super(true) {
    _load();
  }

  static const _key = 'furigana_visible';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_key) ?? true;
    } catch (_) {}
  }

  Future<void> toggle() async {
    final next = !state;
    state = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, next);
    } catch (_) {}
  }
}

final furiganaProvider = StateNotifierProvider<FuriganaNotifier, bool>(
  (ref) => FuriganaNotifier(),
);

