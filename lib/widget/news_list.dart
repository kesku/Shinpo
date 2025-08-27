import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shinpo/error_reporter.dart';
import 'package:shinpo/model/news.dart';
import 'package:shinpo/providers/bookmark_provider.dart';
import 'package:shinpo/providers/theme_provider.dart';
import 'package:shinpo/providers/cache_manager_provider.dart';
import 'package:shinpo/service/cached_news_service.dart';
import 'package:shinpo/service/config_service.dart';
import 'package:shinpo/widget/bookmarks_screen.dart';
import 'package:shinpo/widget/settings.dart';
import 'package:shinpo/widget/search_screen.dart';
import 'package:shinpo/widget/ruby_text_widget.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'news_detail.dart';

class NewsList extends ConsumerStatefulWidget {
  @override
  ConsumerState<NewsList> createState() => NewsListState();
}

class NewsListState extends ConsumerState<NewsList> {
  final _refreshController = RefreshController(initialRefresh: false);
  final _cachedNewsService = CachedNewsService();
  final _newsFetchIntervalDays = 14;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cachedNewsProvider.notifier).loadAllCachedNews();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = ref.read(themeModeProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final cachedNews = ref.watch(cachedNewsProvider);
    final isOffline = ref.watch(offlineModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              '新報',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
            ),
            isOffline
                ? Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'OFFLINE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                : Container(),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (context) => SearchScreen()),
              );
            },
            tooltip: 'Search articles',
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            tooltip: 'More options',
            onSelected: (value) {
              switch (value) {
                case 'theme':
                  themeNotifier.toggleTheme();
                  break;
                case 'bookmarks':
                  _openBookmarks();
                  break;
                case 'settings':
                  _openSettings();
                  break;
                case 'refresh_cache':
                  _forceCacheRefresh();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'refresh_cache',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 12),
                    Text('Refresh Cache'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(Icons.palette_outlined),
                    SizedBox(width: 12),
                    Text('Theme: ${themeNotifier.currentThemeName}'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'bookmarks',
                child: Row(
                  children: [
                    Icon(Icons.bookmark_border),
                    SizedBox(width: 12),
                    Text('Bookmarks'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: cachedNews.when(
        data: (newsList) => _buildNewsList(newsList),
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading news articles...',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: colorScheme.error),
              SizedBox(height: 16),
              Text(
                'Failed to load news',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: colorScheme.error),
              ),
              SizedBox(height: 8),
              Text(
                _getErrorMessage(error),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      ref.read(cachedNewsProvider.notifier).loadAllCachedNews();
                    },
                    child: Text('Load Cached'),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(cachedNewsProvider.notifier).refreshCache();
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsList(List<News> newsList) {
    if (newsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 16),
            Text(
              'No articles yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            SizedBox(height: 8),
            Text(
              'Pull down to refresh',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return SmartRefresher(
      enablePullDown: true,
      enablePullUp: true,
      controller: _refreshController,
      onRefresh: _refreshNewsList,
      onLoading: _loadNewsList,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, i) {
          return _buildNewsCard(newsList[i]);
        },
        itemCount: newsList.length,
      ),
    );
  }

  Widget _buildNewsCard(News news) {
    final publishedDate = DateTime.parse(news.publishedAtUtc).toLocal();
    final formattedDate =
        '${publishedDate.month}/${publishedDate.day}/${publishedDate.year}';
    final formattedTime =
        '${publishedDate.hour.toString().padLeft(2, '0')}:${publishedDate.minute.toString().padLeft(2, '0')}';

    return Consumer(
      builder: (context, ref, child) {
        final bookmarkedNewsIds = ref.watch(bookmarkedNewsIdsProvider);
        final isBookmarked = bookmarkedNewsIds.contains(news.newsId);

        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (context) => NewsDetail(news)),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (news.imageUrl.isNotEmpty)
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: news.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        child: Center(
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: RubyTextWidget(
                              text: news.titleWithRuby,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                  ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isBookmarked)
                            Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.bookmark,
                                color: Colors.amber,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_outlined,
                            size: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '$formattedDate $formattedTime',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                          ),
                          Spacer(),
                          if (news.m3u8Url.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.volume_up_outlined,
                                    size: 14,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSecondaryContainer,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Audio',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSecondaryContainer,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  _refreshNewsList() async {
    try {
      final currentNews = ref.read(cachedNewsProvider).value ?? [];
      final config = await ConfigService().getConfig();

      final latestNews = currentNews.isEmpty ? null : currentNews.first;
      final useConfigDate = config != null && latestNews == null;

      DateTime newestDate = latestNews == null
          ? (config != null
                  ? DateTime.parse(config.newsFetchedEndUtc)
                  : DateTime.now().toUtc())
              .subtract(Duration(days: _newsFetchIntervalDays))
          : DateTime.parse(latestNews.publishedAtUtc).add(Duration(days: 1));

      DateTime startDate = DateTime.utc(
        newestDate.year,
        newestDate.month,
        newestDate.day,
        0,
        0,
        0,
      );

      DateTime endDate = useConfigDate
          ? DateTime.parse(config.newsFetchedEndUtc)
          : DateTime.utc(
              newestDate.year,
              newestDate.month,
              newestDate.day,
              23,
              59,
              59,
            ).add(Duration(days: _newsFetchIntervalDays));

      final newsList = await _cachedNewsService.fetchNewsList(
        startDate,
        endDate,
      );

      if (newsList.isNotEmpty) {
        await ref.read(cachedNewsProvider.notifier).loadAllCachedNews();
      }

      _refreshController.refreshCompleted();
    } catch (error, stackTrace) {
      ErrorReporter.reportError(error, stackTrace);
      Fluttertoast.showToast(
        msg: 'Network error',
        gravity: ToastGravity.CENTER,
      );
      _refreshController.refreshFailed();
    }
  }

  _loadNewsList() async {
    try {
      final currentNews = ref.read(cachedNewsProvider).value ?? [];

      final lastNews = currentNews.isEmpty ? null : currentNews.last;
      DateTime oldestDate = lastNews == null
          ? DateTime.now().toUtc()
          : DateTime.parse(lastNews.publishedAtUtc).subtract(Duration(days: 1));

      DateTime startDate = DateTime.utc(
        oldestDate.year,
        oldestDate.month,
        oldestDate.day,
        0,
        0,
        0,
      ).subtract(Duration(days: _newsFetchIntervalDays));

      DateTime endDate = DateTime.utc(
        oldestDate.year,
        oldestDate.month,
        oldestDate.day,
        23,
        59,
        59,
      );

      final newsList = await _cachedNewsService.fetchNewsList(
        startDate,
        endDate,
      );

      if (newsList.isNotEmpty) {
        await ref.read(cachedNewsProvider.notifier).loadAllCachedNews();
        _refreshController.loadComplete();
      } else {
        _refreshController.loadNoData();
      }
    } catch (error, stackTrace) {
      ErrorReporter.reportError(error, stackTrace);
      Fluttertoast.showToast(
        msg: 'Network error',
        gravity: ToastGravity.CENTER,
      );
      _refreshController.loadFailed();
    }
  }

  void _forceCacheRefresh() async {
    try {
      await ref.read(cachedNewsProvider.notifier).refreshCache();

      Fluttertoast.showToast(
        msg: 'Cache refreshed successfully',
        gravity: ToastGravity.CENTER,
      );
    } catch (error) {
      final errorString = error.toString();
      String message = 'Failed to refresh cache';

      if (errorString.contains('Server temporarily unavailable') ||
          errorString.contains('Server error') ||
          errorString.contains('HTTP 500')) {
        message = 'Server is temporarily unavailable. Using cached data.';
      } else if (errorString.contains('Network connection failed') ||
          errorString.contains('SocketException') ||
          errorString.contains('TimeoutException')) {
        message = 'Network connection failed. Using cached data.';
      }

      Fluttertoast.showToast(
        msg: message,
        gravity: ToastGravity.CENTER,
      );

      await ref.read(cachedNewsProvider.notifier).loadAllCachedNews();
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorString = error.toString();

    if (errorString.contains('Server temporarily unavailable')) {
      return 'The news server is temporarily unavailable.\nPlease try again later.';
    } else if (errorString.contains('Server error')) {
      return 'The news server is experiencing issues.\nPlease try again later.';
    } else if (errorString.contains('Network connection failed')) {
      return 'Unable to connect to the internet.\nPlease check your connection and try again.';
    } else if (errorString.contains('Request error')) {
      return 'There was an issue with the request.\nPlease check your connection.';
    } else if (errorString.contains('HTTP 500')) {
      return 'Server error occurred.\nPlease try again later.';
    } else {
      return 'An unexpected error occurred.\nPlease try again.';
    }
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return Settings();
        },
      ),
    );
  }

  void _openBookmarks() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return BookmarksScreen();
        },
      ),
    );
  }
}
