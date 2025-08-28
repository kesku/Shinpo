import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinpo/model/news.dart';
import 'package:shinpo/providers/bookmark_provider.dart';
import 'package:shinpo/providers/theme_provider.dart';
import 'package:shinpo/service/cached_news_service.dart';
import 'package:shinpo/widget/news_detail.dart';
import 'package:shinpo/widget/ruby_text_widget.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shinpo/util/navigation.dart';

class BookmarksScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<BookmarksScreen> createState() => BookmarksScreenState();
}

class BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  final _cachedNewsService = CachedNewsService();
  final _bookmarkedNews = <News>[];
  bool _isLoading = false;
  final _refreshController = RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    _loadBookmarkedNews();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadBookmarkedNews();
  }

  Future<void> _loadBookmarkedNews() async {
    setState(() {
      _isLoading = true;
    });

    final bookmarkedNewsIds = ref.read(bookmarkedNewsIdsProvider);
    if (bookmarkedNewsIds.isEmpty) {
      setState(() {
        _bookmarkedNews.clear();
        _isLoading = false;
      });
      return;
    }

    try {
      final allNews = await _cachedNewsService.getAllNews();

      final bookmarkedNews = allNews
          .where((news) => bookmarkedNewsIds.contains(news.newsId))
          .toList();

      bookmarkedNews.sort(
        (a, b) => b.publishedAtEpoch.compareTo(a.publishedAtEpoch),
      );

      setState(() {
        _bookmarkedNews.clear();
        _bookmarkedNews.addAll(bookmarkedNews);
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onRefresh() async {
    await _loadBookmarkedNews();
    _refreshController.refreshCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = ref.read(themeModeProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bookmarks',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        actions: <Widget>[
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            tooltip: 'More options',
            onSelected: (value) {
              switch (value) {
                case 'theme':
                  themeNotifier.toggleTheme();
                  break;
              }
            },
            itemBuilder: (context) => [
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
            ],
          ),
        ],
      ),
      body: SmartRefresher(
        enablePullDown: true,
        controller: _refreshController,
        onRefresh: _onRefresh,
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _bookmarkedNews.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bookmark_border,
                      size: 64,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No bookmarks yet',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Bookmark articles to see them here',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 8),
                itemBuilder: (context, i) {
                  return _buildNewsCard(_bookmarkedNews[i]);
                },
                itemCount: _bookmarkedNews.length,
              ),
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
        return Dismissible(
          key: Key(news.newsId),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 20),
            color: Colors.red,
            child: Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Remove Bookmark'),
                  content: Text(
                    'Are you sure you want to remove this bookmark?',
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text('Remove'),
                    ),
                  ],
                );
              },
            );
          },
          onDismissed: (direction) async {
            final bookmarkNotifier = ref.read(
              bookmarkedNewsIdsProvider.notifier,
            );
            await bookmarkNotifier.removeBookmark(news.newsId);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Bookmark removed'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          },
          child: Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  platformPageRoute<void>(
                    builder: (context) => NewsDetail(news),
                  ),
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
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
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
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      height: 1.3,
                                    ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
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
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
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
          ),
        );
      },
    );
  }
}
