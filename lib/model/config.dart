import 'package:shinpo/util/date_validation.dart';

class Config {
  int id = 0;

  String newsFetchedStartUtc = '';

  String newsFetchedEndUtc = '';

  Config(
      {required this.id,
      required this.newsFetchedStartUtc,
      required this.newsFetchedEndUtc});

  factory Config.fromJson(Map<String, dynamic> json) {
    final config =
        Config(id: 0, newsFetchedStartUtc: '', newsFetchedEndUtc: '');
    config.id = json['id'];
    config.newsFetchedStartUtc = json['newsFetchedStartUtc'];
    config.newsFetchedEndUtc = json['newsFetchedEndUtc'];

    if (!DateValidation.isValidDateString(config.newsFetchedStartUtc)) {
      config.newsFetchedStartUtc = DateTime.now().toUtc().toIso8601String();
    }

    if (!DateValidation.isValidDateString(config.newsFetchedEndUtc)) {
      config.newsFetchedEndUtc = DateTime.now().toUtc().toIso8601String();
    }

    return config;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'newsFetchedStartUtc': newsFetchedStartUtc,
      'newsFetchedEndUtc': newsFetchedEndUtc
    };
  }

  bool isValid() {
    return DateValidation.isValidDateString(newsFetchedStartUtc) &&
        DateValidation.isValidDateString(newsFetchedEndUtc) &&
        _isValidDateRange();
  }

  bool _isValidDateRange() {
    try {
      final startDate = DateTime.parse(newsFetchedStartUtc);
      final endDate = DateTime.parse(newsFetchedEndUtc);
      return startDate.isBefore(endDate) || startDate.isAtSameMomentAs(endDate);
    } catch (e) {
      return false;
    }
  }
}
