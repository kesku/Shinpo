import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinpo/providers/reading_history_provider.dart';
import 'package:shinpo/service/cached_news_service.dart';
import 'package:shinpo/widget/news_detail.dart';

class ReadingHistoryScreen extends ConsumerWidget {
  const ReadingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(readingHistoryProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading History'),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _showClearHistoryDialog(context, ref),
              tooltip: 'Clear History',
            ),
        ],
      ),
      body: history.isEmpty
          ? _buildEmptyState(colorScheme)
          : _buildHistoryList(context, history, colorScheme),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'No Reading History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Articles you read will appear here',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(
    BuildContext context,
    List<ReadingHistoryItem> history,
    ColorScheme colorScheme,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  _formatReadTime(item.readAt),
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                if (item.readProgress > 0)
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: item.readProgress / 100,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${item.readProgress}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            leading: CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                item.readProgress == 100 ? Icons.check : Icons.article,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            onTap: () {
              _showNewsDetail(context, item);
            },
          ),
        );
      },
    );
  }

  String _formatReadTime(DateTime readAt) {
    final now = DateTime.now();
    final difference = now.difference(readAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  void _showClearHistoryDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Reading History'),
        content: const Text(
          'Are you sure you want to clear all reading history? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(readingHistoryProvider.notifier).clearHistory();
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showNewsDetail(BuildContext context, ReadingHistoryItem item) async {
    final cachedNewsService = CachedNewsService();

    try {
      final news = await cachedNewsService.getNewsById(item.newsId);

      if (news != null) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => NewsDetail(news),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Article not found in cache. Please refresh your news.'),
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load article. Please try again.'),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
    }
  }
}
