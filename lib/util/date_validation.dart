/// Centralized date validation utilities used across services and models.
class DateValidation {
  /// Validates a DateTime is within an acceptable range.
  /// Range: after 2020-01-01 and before now + 365 days (UTC).
  static bool isValidDate(DateTime date) {
    try {
      final now = DateTime.now().toUtc();
      final minDate = DateTime(2020, 1, 1);
      final maxDate = now.add(const Duration(days: 365));
      return date.isAfter(minDate) && date.isBefore(maxDate);
    } catch (_) {
      return false;
    }
  }

  /// Parses and validates an ISO-8601 date string using [isValidDate].
  static bool isValidDateString(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return isValidDate(date);
    } catch (_) {
      return false;
    }
  }

  /// Validates that [start] is before or equal to [end] and both valid.
  static bool isValidRange(DateTime start, DateTime end) {
    try {
      return isValidDate(start) && isValidDate(end) &&
          (start.isBefore(end) || start.isAtSameMomentAs(end));
    } catch (_) {
      return false;
    }
  }
}

