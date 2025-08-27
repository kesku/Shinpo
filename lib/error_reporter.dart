class ErrorReporter {
  static Future<void> reportError(dynamic error, dynamic stackTrace) async {
    print('Error: $error');
    print('StackTrace: $stackTrace');
  }
}
