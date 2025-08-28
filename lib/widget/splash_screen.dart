import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinpo/providers/cache_manager_provider.dart';
import 'package:shinpo/widget/news_list.dart';
import 'package:shinpo/util/navigation.dart';

class SplashScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _optimizationComplete = false;

  @override
  void initState() {
    super.initState();
    _performCacheOptimization();
  }

  Future<void> _performCacheOptimization() async {
    try {
      
      final cacheManager = ref.read(cacheManagerServiceProvider);
      await cacheManager.optimizeCache();
    } catch (e) {
      
      print('Cache optimization failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _optimizationComplete = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                if (_optimizationComplete) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.of(context).pushReplacement(
                      platformPageRoute(builder: (context) => NewsList()),
                    );
                  });
                }
                return _buildLoadingContent(
                  context,
                  _optimizationComplete ? 'Loading complete!' : 'Optimizing cache...',
                  _optimizationComplete ? Icons.check_circle_outline : null,
                  _optimizationComplete ? Colors.green : null,
                );
              },
              loading: () => _buildLoadingContent(
                context,
                _optimizationComplete ? 'Loading news articles...' : 'Optimizing cache...',
                null,
                null,
              ),
              error: (error, stackTrace) {
                if (_optimizationComplete) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.of(context).pushReplacement(
                      platformPageRoute(builder: (context) => NewsList()),
                    );
                  });
                }
                return Column(
                  children: [
                    _buildLoadingContent(
                      context,
                      _optimizationComplete ? 'Loading from cache...' : 'Optimizing cache...',
                      _optimizationComplete ? Icons.cloud_off_outlined : null,
                      _optimizationComplete ? Colors.orange : null,
                    ),
                    SizedBox(height: 16),
                    if (_optimizationComplete && isOffline) 
                      _buildOfflineIndicator(context),
                    SizedBox(height: 16),
                    if (_optimizationComplete)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            platformPageRoute(builder: (context) => NewsList()),
                          );
                        },
                        child: Text('Continue'),
                      ),
                  ],
                );
              },
            ),
            SizedBox(height: 24),
            if (_optimizationComplete && isOffline) 
              _buildOfflineIndicator(context),
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
