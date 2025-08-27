import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shinpo/error_reporter.dart';
import 'package:shinpo/providers/theme_provider.dart';
import 'package:shinpo/providers/cache_manager_provider.dart';
import 'package:shinpo/repository/base_repository.dart';
import 'package:shinpo/widget/font_size_dialog.dart';
import 'package:shinpo/widget/reading_history_screen.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class Settings extends ConsumerStatefulWidget {
  @override
  ConsumerState<Settings> createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<Settings> {
  final _baseRepository = BaseRepository();
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = packageInfo;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = ref.read(themeModeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: Text('Appearance'),
            tiles: [
              SettingsTile(
                title: Text('Theme'),
                description: Text('Current: ${themeNotifier.currentThemeName}'),
                leading: Icon(Icons.palette_outlined),
                onPressed: (context) => _showThemeDialog(context, ref),
              ),
            ],
          ),
          SettingsSection(
            title: Text('Reading'),
            tiles: [
              SettingsTile(
                title: Text('Text Size'),
                description: Text('Adjust font size for better reading'),
                leading: Icon(Icons.text_fields),
                onPressed: (context) {
                  showDialog(
                    context: context,
                    builder: (context) => const FontSizeDialog(),
                  );
                },
              ),
              SettingsTile(
                title: Text('Reading History'),
                description: Text('View your reading progress'),
                leading: Icon(Icons.history),
                onPressed: (context) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ReadingHistoryScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          SettingsSection(
            title: Text('Cache & Storage'),
            tiles: [
              SettingsTile(
                title: Text('Cache Status'),
                description: Text('View cache information'),
                leading: Icon(Icons.info_outline),
                onPressed: (context) => _showCacheStatus(context, ref),
              ),
              SettingsTile(
                title: Text('Refresh Cache'),
                description: Text('Download latest articles'),
                leading: Icon(Icons.refresh),
                onPressed: (context) => _refreshCache(context, ref),
              ),
              SettingsTile(
                title: Text('Clear Cache'),
                description: Text('Free up storage space'),
                leading: Icon(Icons.storage),
                onPressed: _clearCache,
              ),
            ],
          ),
          SettingsSection(
            title: Text('About'),
            tiles: [
              SettingsTile(
                title: Text('Privacy Policy'),
                leading: Icon(Icons.description),
                onPressed: _openPrivacyPolicy,
              ),
              SettingsTile(
                title: Text('Version'),
                description: Text(
                    _packageInfo != null 
                        ? '${_packageInfo!.version}+${_packageInfo!.buildNumber}'
                        : 'Loading...'),
                leading: Icon(Icons.info_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final themeNotifier = ref.read(themeModeProvider.notifier);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) {
            final title = mode == ThemeMode.light
                ? 'Light'
                : mode == ThemeMode.dark
                    ? 'Dark'
                    : 'System';

            return RadioListTile<ThemeMode>(
              title: Text(title),
              subtitle: mode == ThemeMode.system
                  ? Text('Follow system setting')
                  : null,
              value: mode,
              groupValue: ref.watch(themeModeProvider),
              onChanged: (value) {
                if (value != null) {
                  themeNotifier.setThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _clearCache(BuildContext context) {
    final yesButton = TextButton(
      child: Text(
        'Yes',
        style: TextStyle(color: Colors.red),
      ),
      onPressed: () {
        _baseRepository.dropDatabase().then((value) {
          Navigator.pop(context);

          Fluttertoast.showToast(
              msg: 'Cache removed', gravity: ToastGravity.CENTER);
        }).catchError((error, stackTrace) {
          Navigator.pop(context);

          Fluttertoast.showToast(
              msg: 'Failed to remove cache', gravity: ToastGravity.CENTER);

          ErrorReporter.reportError(error, stackTrace);
        });
      },
    );
    final noButton = TextButton(
      child: Text('No'),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    final alertDialog = AlertDialog(
      content: Text('Are you sure to clear cached data?'),
      actions: <Widget>[yesButton, noButton],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alertDialog;
      },
    );
  }

  void _openPrivacyPolicy(BuildContext context) async {
    final url =
        'https://github.com/kesku/Shinpo/blob/master/privacy_policy.md';
    final uri = Uri.parse(url);

    try {
      await launchUrl(uri);
    } catch (e) {
      final okButton = TextButton(
        child: Text('Ok'),
        onPressed: () {
          Navigator.pop(context);
        },
      );
      final alertDialog = AlertDialog(
        content: Text(
            'Failed to open privacy policy in your default browser, you can view it at $url'),
        actions: <Widget>[okButton],
      );

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return alertDialog;
        },
      );
    }
  }

  void _showCacheStatus(BuildContext context, WidgetRef ref) async {
    final cacheStatus = await ref.read(cacheStatusProvider.future);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cache Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusRow(
                'Initialized', cacheStatus['initialized'].toString()),
            SizedBox(height: 8),
            _buildStatusRow(
                'Articles Cached', cacheStatus['articleCount'].toString()),
            SizedBox(height: 8),
            _buildStatusRow(
                'Last Updated',
                cacheStatus['lastUpdate'] != null
                    ? _formatDateTime(cacheStatus['lastUpdate'])
                    : 'Never'),
            SizedBox(height: 8),
            _buildStatusRow('Internet Connection',
                cacheStatus['hasInternetConnection'] ? 'Available' : 'Offline'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            '$label:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(value),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _refreshCache(BuildContext context, WidgetRef ref) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Refreshing cache...'),
            ],
          ),
        ),
      );

      await ref.read(cachedNewsProvider.notifier).refreshCache();

      if (!context.mounted) return;

      Navigator.of(context).pop();

      Fluttertoast.showToast(
        msg: 'Cache refreshed successfully',
        gravity: ToastGravity.CENTER,
      );
    } catch (error) {
      if (!context.mounted) return;

      Navigator.of(context).pop();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to refresh cache: ${error.toString()}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
