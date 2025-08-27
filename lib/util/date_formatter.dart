/// Formats dates for the NHK API with millisecond precision in UTC.
/// Example: YYYY-MM-DDTHH:MM:SS.sssZ
String formatDateForApi(DateTime date) {
  final utcDate = date.toUtc();
  final iso = utcDate.toIso8601String();
  // Ensure millisecond precision and 'Z' suffix
  return iso.substring(0, 23) + 'Z';
}

