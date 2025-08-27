import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shinpo/error_reporter.dart';
import 'package:shinpo/providers/theme_provider.dart';
import 'package:shinpo/providers/cache_manager_provider.dart';
import 'package:shinpo/providers/font_size_provider.dart';
import 'package:shinpo/providers/furigana_provider.dart';
import 'package:shinpo/widget/reading_history_screen.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeNotifier = ref.read(themeModeProvider.notifier);
    final themeMode = ref.watch(themeModeProvider);
    final fontSize = ref.watch(fontSizeProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Settings'),
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: _Section(
              title: 'Appearance',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(icon: Icons.palette_outlined, label: 'Theme'),
                  const SizedBox(height: 8),
                  SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('System'),
                          icon: Icon(Icons.phone_iphone)),
                      ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Light'),
                          icon: Icon(Icons.light_mode_outlined)),
                      ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                          icon: Icon(Icons.dark_mode_outlined)),
                    ],
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                    selected: {themeMode},
                    onSelectionChanged: (selection) {
                      final mode = selection.first;
                      themeNotifier.setThemeMode(mode);
                    },
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _Section(
              title: 'Reading',
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.text_fields),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    trailing: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: SegmentedButton<FontSizeLevel>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                              value: FontSizeLevel.small, label: Text('S')),
                          ButtonSegment(
                              value: FontSizeLevel.normal, label: Text('M')),
                          ButtonSegment(
                              value: FontSizeLevel.large, label: Text('L')),
                          ButtonSegment(
                              value: FontSizeLevel.extraLarge,
                              label: Text('XL')),
                        ],
                        selected: {fontSize},
                        onSelectionChanged: (selection) {
                          ref
                              .read(fontSizeProvider.notifier)
                              .setFontSize(selection.first);
                        },
                      ),
                    ),
                  ),
                  SwitchListTile.adaptive(
                    value: ref.watch(furiganaProvider),
                    onChanged: (_) =>
                        ref.read(furiganaProvider.notifier).toggle(),
                    secondary: const Icon(Icons.translate_outlined),
                    title: const Text('Show Furigana'),
                    subtitle:
                        const Text('Display pronunciation guides above kanji'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  const SizedBox(height: 4),
                  _TileButton(
                    icon: Icons.history,
                    title: 'Reading History',
                    subtitle: 'View your reading progress',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ReadingHistoryScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _Section(
              title: 'Cache & Storage',
              child: Column(
                children: [
                  _TileButton(
                    icon: Icons.info_outline,
                    title: 'Cache Status',
                    subtitle: 'View cache information',
                    onTap: () => _showCacheStatus(context, ref),
                  ),
                  _TileButton(
                    icon: Icons.sync,
                    title: 'Refresh Cache',
                    subtitle: 'Download latest articles',
                    onTap: () => _refreshCache(context, ref),
                  ),
                  _TileButton(
                    icon: Icons.cleaning_services_outlined,
                    title: 'Optimize Cache',
                    subtitle: 'Clean up and validate cache',
                    onTap: () => _optimizeCache(context, ref),
                  ),
                  ListTile(
                    leading:
                        Icon(Icons.delete_outline, color: colorScheme.error),
                    title: Text('Clear Cache',
                        style: TextStyle(
                          color: colorScheme.error,
                          fontWeight: FontWeight.w600,
                        )),
                    subtitle: const Text('Free up storage space'),
                    onTap: () => _clearCache(context),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _Section(
              title: 'About',
              child: Column(
                children: [
                  _TileButton(
                    icon: Icons.description_outlined,
                    title: 'Privacy Policy',
                    onTap: () => _openPrivacyPolicy(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Version'),
                    subtitle: Text(
                      _packageInfo != null
                          ? '${_packageInfo!.version}+${_packageInfo!.buildNumber}'
                          : 'Loading...',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
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
    final url = 'https://github.com/kesku/Shinpo/blob/master/privacy_policy.md';
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
              _buildStatusRow('Cache Valid', cacheStatus['isValid'].toString()),
              SizedBox(height: 8),
              if (cacheStatus['hitRate'] != null)
                _buildStatusRow('Cache Hit Rate',
                    '${cacheStatus['hitRate'].toStringAsFixed(1)}%'),
              SizedBox(height: 8),
              if (cacheStatus['totalRequests'] != null &&
                  cacheStatus['totalRequests'] > 0)
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
                _buildStatusRow('Oldest Article',
                    _formatDateTime(cacheStatus['oldestDate'])),
              SizedBox(height: 8),
              if (cacheStatus['newestDate'] != null)
                _buildStatusRow('Newest Article',
                    _formatDateTime(cacheStatus['newestDate'])),
              SizedBox(height: 8),
              _buildStatusRow(
                  'Internet Connection',
                  cacheStatus['hasInternetConnection']
                      ? 'Available'
                      : 'Offline'),
              SizedBox(height: 8),
              _buildStatusRow(
                  'NHK Server',
                  cacheStatus['nhkServerReachable']
                      ? 'Reachable'
                      : 'Unreachable'),
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

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Text(
          label,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _TileButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _TileButton({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    );
  }
}
