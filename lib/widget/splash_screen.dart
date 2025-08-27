import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinpo/providers/cache_manager_provider.dart';
import 'package:shinpo/widget/news_list.dart';

class SplashScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cacheInitialization = ref.watch(cacheInitializationProvider);
    final isOffline = ref.watch(offlineModeProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.newspaper,
                size: 60,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            SizedBox(height: 32),
            Text(
              '新報',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            SizedBox(height: 16),
            cacheInitialization.when(
              data: (news) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => NewsList()),
                  );
                });
                return _buildLoadingContent(
                  context,
                  'Loading complete!',
                  Icons.check_circle_outline,
                  Colors.green,
                );
              },
              loading: () => _buildLoadingContent(
                context,
                'Loading news articles...',
                null,
                null,
              ),
              error: (error, stackTrace) {
                return Column(
                  children: [
                    _buildLoadingContent(
                      context,
                      'Loading from cache...',
                      Icons.cloud_off_outlined,
                      Colors.orange,
                    ),
                    SizedBox(height: 16),
                    isOffline ? _buildOfflineIndicator(context) : Container(),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => NewsList()),
                        );
                      },
                      child: Text('Continue'),
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: 24),
            isOffline ? _buildOfflineIndicator(context) : Container(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingContent(
    BuildContext context,
    String message,
    IconData? icon,
    Color? iconColor,
  ) {
    return Column(
      children: [
        if (icon != null)
          Icon(
            icon,
            size: 32,
            color: iconColor ?? Theme.of(context).colorScheme.primary,
          )
        else
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
            ),
          ),
        SizedBox(height: 16),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOfflineIndicator(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 16,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          SizedBox(width: 8),
          Text(
            'Offline Mode',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
