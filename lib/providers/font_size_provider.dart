import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FontSizeLevel {
  small(0.9, 'Small'),
  normal(1.0, 'Normal'),
  large(1.1, 'Large'),
  extraLarge(1.2, 'Extra Large');

  const FontSizeLevel(this.scale, this.displayName);

  final double scale;
  final String displayName;
}

class FontSizeNotifier extends StateNotifier<FontSizeLevel> {
  FontSizeNotifier() : super(FontSizeLevel.normal) {
    _loadFontSize();
  }

  static const String _fontSizeKey = 'font_size_level';

  Future<void> _loadFontSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fontSizeIndex = prefs.getInt(_fontSizeKey);

      if (fontSizeIndex != null &&
          fontSizeIndex >= 0 &&
          fontSizeIndex < FontSizeLevel.values.length) {
        state = FontSizeLevel.values[fontSizeIndex];
      }
    } catch (e) {
      state = FontSizeLevel.normal;
    }
  }

  Future<void> setFontSize(FontSizeLevel fontSize) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_fontSizeKey, fontSize.index);
      state = fontSize;
    } catch (e) {}
  }
}

final fontSizeProvider = StateNotifierProvider<FontSizeNotifier, FontSizeLevel>(
  (ref) => FontSizeNotifier(),
);
