import 'package:shinpo/error_reporter.dart';
import 'package:shinpo/model/config.dart';
import 'package:shinpo/repository/config_repository.dart';

class ConfigService {
  final _configRepository = ConfigRepository();

  Future<Config?> getConfig() async {
    try {
      return await _configRepository.getConfig();
    } catch (error, stackTrace) {
      ErrorReporter.reportError(error, stackTrace);
    }

    return null;
  }
}
