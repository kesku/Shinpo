import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Locale-aware date/time helpers used across list and detail screens.
class DateLocaleUtils {
  static String formatAbsolute(BuildContext context, DateTime dateTime) {
    final locale = Localizations.maybeLocaleOf(context)?.toString();
    final df = DateFormat.yMd(locale).add_Hm();
    return df.format(dateTime);
  }

  static String formatRelative(DateTime dateTime, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    final diff = ref.difference(dateTime);

    if (diff.inDays >= 1) {
      final d = diff.inDays;
      return '${d} day${d == 1 ? '' : 's'} ago';
    }
    if (diff.inHours >= 1) {
      final h = diff.inHours;
      return '${h} hour${h == 1 ? '' : 's'} ago';
    }
    if (diff.inMinutes >= 1) {
      final m = diff.inMinutes;
      return '${m} minute${m == 1 ? '' : 's'} ago';
    }
    return 'just now';
  }

  static String relativePlusAbsolute(BuildContext context, DateTime dateTime) {
    return '${formatRelative(dateTime)} · ${formatAbsolute(context, dateTime)}';
  }
}

