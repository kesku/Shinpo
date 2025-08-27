/// Formats dates for the NHK API with millisecond precision in UTC.
/// Example: YYYY-MM-DDTHH:MM:SS.sssZ
String formatDateForApi(DateTime date) {
  final d = date.toUtc();

  String two(int n) => n.toString().padLeft(2, '0');
  String three(int n) => n.toString().padLeft(3, '0');

  final y = d.year.toString().padLeft(4, '0');
  final mo = two(d.month);
  final da = two(d.day);
  final h = two(d.hour);
  final mi = two(d.minute);
  final s = two(d.second);
  final ms = three(d.millisecond);

  return '$y-$mo-${da}T$h:$mi:${s}.${ms}Z';
}
