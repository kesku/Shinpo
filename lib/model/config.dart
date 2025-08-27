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

    
    if (!config._isValidDateString(config.newsFetchedStartUtc)) {
      print('Config.fromJson: Invalid start date: ${config.newsFetchedStartUtc}');
      config.newsFetchedStartUtc = DateTime.now().toUtc().toIso8601String();
    }
    
    if (!config._isValidDateString(config.newsFetchedEndUtc)) {
      print('Config.fromJson: Invalid end date: ${config.newsFetchedEndUtc}');
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
    return _isValidDateString(newsFetchedStartUtc) && 
           _isValidDateString(newsFetchedEndUtc) &&
           _isValidDateRange();
  }

  bool _isValidDateString(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now().toUtc();
      final minDate = DateTime(2020, 1, 1);
      final maxDate = now.add(Duration(days: 365));
      
      return date.isAfter(minDate) && date.isBefore(maxDate);
    } catch (e) {
      return false;
    }
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
