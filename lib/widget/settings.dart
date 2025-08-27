import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shinpo/error_reporter.dart';
import 'package:shinpo/providers/theme_provider.dart';
import 'package:shinpo/providers/cache_manager_provider.dart';
import 'package:shinpo/widget/font_size_dialog.dart';
import 'package:shinpo/widget/reading_history_screen.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class Settings extends ConsumerStatefulWidget {
  @override
  ConsumerState<Settings> createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<Settings> {
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
              SettingsTile.navigation(
                title: Text('Theme'),
                value: Text(themeNotifier.currentThemeName),
                leading: Icon(Icons.palette_outlined),
                onPressed: (context) => _showThemeDialog(context, ref),
              ),
            ],
          ),
          SettingsSection(
            title: Text('Reading'),
            tiles: [
              SettingsTile.navigation(
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
              SettingsTile.navigation(
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
              SettingsTile.navigation(
                title: Text('Cache Status'),
                description: Text('View cache information'),
                leading: Icon(Icons.info_outline),
                onPressed: (context) => _showCacheStatus(context, ref),
              ),
              SettingsTile.navigation(
                title: Text('Refresh Cache'),
                description: Text('Download latest articles'),
                leading: Icon(Icons.sync),
                onPressed: (context) => _refreshCache(context, ref),
              ),
              SettingsTile.navigation(
                title: Text('Optimize Cache'),
                description: Text('Clean up and validate cache'),
                leading: Icon(Icons.cleaning_services_outlined),
                onPressed: (context) => _optimizeCache(context, ref),
              ),
              SettingsTile.navigation(
                title: Text(
                  'Clear Cache',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                description: Text('Free up storage space'),
                leading: Icon(Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error),
                onPressed: _clearCache,
              ),
            ],
          ),
          SettingsSection(
            title: Text('About'),
            tiles: [
              SettingsTile.navigation(
                title: Text('Privacy Policy'),
                leading: Icon(Icons.description_outlined),
                onPressed: _openPrivacyPolicy,
              ),
              SettingsTile(
                title: Text('Version'),
                value: Text(
                  _packageInfo != null
                      ? '${_packageInfo!.version}+${_packageInfo!.buildNumber}'
                      : 'Loading...',
                ),
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
      onPressed: () async {
        Navigator.pop(context);
        
        try {
          final cacheManager = ref.read(cacheManagerServiceProvider);
          await cacheManager.clearAllCache();
          
          
          ref.invalidate(cachedNewsProvider);
          ref.invalidate(cacheStatusProvider);
          ref.invalidate(cacheInitializationProvider);
          
          Fluttertoast.showToast(
              msg: 'Cache removed', gravity: ToastGravity.CENTER);
        } catch (error, stackTrace) {
          Fluttertoast.showToast(
              msg: 'Failed to remove cache', gravity: ToastGravity.CENTER);

          ErrorReporter.reportError(error, stackTrace);
        }
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
        content: SingleChildScrollView(
          child: Column(
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
                  'Cache Size', cacheStatus['cacheSize'].toString()),
              SizedBox(height: 8),
              _buildStatusRow(
                  'Cache Valid', cacheStatus['isValid'].toString()),
              SizedBox(height: 8),
              if (cacheStatus['hitRate'] != null)
                _buildStatusRow(
                    'Cache Hit Rate', '${cacheStatus['hitRate'].toStringAsFixed(1)}%'),
              SizedBox(height: 8),
              if (cacheStatus['totalRequests'] != null && cacheStatus['totalRequests'] > 0)
                _buildStatusRow(
                    'Total Requests', cacheStatus['totalRequests'].toString()),
              SizedBox(height: 8),
              _buildStatusRow(
                  'Last Updated',
                  cacheStatus['lastUpdate'] != null
                      ? _formatDateTime(cacheStatus['lastUpdate'])
                      : 'Never'),
              SizedBox(height: 8),
              if (cacheStatus['ageInDays'] != null)
                _buildStatusRow(
                    'Cache Age', '${cacheStatus['ageInDays']} days'),
              SizedBox(height: 8),
              if (cacheStatus['oldestDate'] != null)
                _buildStatusRow(
                    'Oldest Article',
                    _formatDateTime(cacheStatus['oldestDate'])),
              SizedBox(height: 8),
              if (cacheStatus['newestDate'] != null)
                _buildStatusRow(
                    'Newest Article',
                    _formatDateTime(cacheStatus['newestDate'])),
              SizedBox(height: 8),
              _buildStatusRow('Internet Connection',
                  cacheStatus['hasInternetConnection'] ? 'Available' : 'Offline'),
              SizedBox(height: 8),
              _buildStatusRow('NHK Server',
                  cacheStatus['nhkServerReachable'] ? 'Reachable' : 'Unreachable'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _optimizeCache(context, ref);
            },
            child: Text('Optimize'),
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

  void _optimizeCache(BuildContext context, WidgetRef ref) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Optimizing cache...'),
            ],
          ),
        ),
      );

      await ref.read(cachedNewsProvider.notifier).optimizeCache();

      if (!context.mounted) return;

      Navigator.of(context).pop();

      Fluttertoast.showToast(
        msg: 'Cache optimized successfully',
        gravity: ToastGravity.CENTER,
      );
    } catch (error) {
      if (!context.mounted) return;

      Navigator.of(context).pop();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to optimize cache: ${error.toString()}'),
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
