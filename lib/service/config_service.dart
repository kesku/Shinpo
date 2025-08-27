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

  Future<void> saveConfig(Config config) async {
    try {
      await _configRepository.save(config);
    } catch (error, stackTrace) {
      ErrorReporter.reportError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> clearConfig() async {
    try {
      final configs = await _configRepository.getConfigs();
      for (final config in configs) {
        await _configRepository.delete(config.id);
      }
    } catch (error, stackTrace) {
      ErrorReporter.reportError(error, stackTrace);
      rethrow;
    }
  }
}
