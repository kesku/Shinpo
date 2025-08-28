class DateValidation {
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

  static bool isValidDateString(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return isValidDate(date);
    } catch (_) {
      return false;
    }
  }

  static bool isValidRange(DateTime start, DateTime end) {
    try {
      return isValidDate(start) &&
          isValidDate(end) &&
          (start.isBefore(end) || start.isAtSameMomentAs(end));
    } catch (_) {
      return false;
    }
  }
}
