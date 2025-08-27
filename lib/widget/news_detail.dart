import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shinpo/error_reporter.dart';
import 'package:shinpo/model/news.dart';
import 'package:shinpo/model/word.dart';
import 'package:shinpo/providers/bookmark_provider.dart';
import 'package:shinpo/providers/font_size_provider.dart';
import 'package:shinpo/providers/reading_history_provider.dart';
import 'package:shinpo/service/word_service.dart';
import 'package:shinpo/widget/ruby_text_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsDetail extends ConsumerStatefulWidget {
  final News news;

  const NewsDetail(this.news, {super.key});

  @override
  ConsumerState<NewsDetail> createState() => NewsDetailState();
}

class NewsDetailState extends ConsumerState<NewsDetail> {
  News? _news;
  bool _isPlaying = false;
  AudioPlayer? _audioPlayer;
  bool _showDictionary = false;
  Word? _currentWord;
  List<Word> _words = [];
  WordService _wordService = WordService();

  @override
  void initState() {
    super.initState();

    this._news = widget.news;
    _audioPlayer = AudioPlayer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(readingHistoryProvider.notifier).addToHistory(_news!);
    });

    if (_hasAudio()) {
      _audioPlayer?.setUrl(_news!.m3u8Url).catchError((error, stackTrace) {
        ErrorReporter.reportError(error, stackTrace);
        return null;
      });
    }

    _wordService
        .fetchWordList(this._news!.newsId)
        .then((words) => this._words = words)
        .catchError((error, stackTrace) {
      ErrorReporter.reportError(error, stackTrace);
      return <Word>[];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (_hasAudio()) {
          try {
            await _audioPlayer?.dispose();
          } catch (error, stackTrace) {
            ErrorReporter.reportError(error, stackTrace);
          }
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          elevation: 0,
          scrolledUnderElevation: 1,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: colorScheme.onSurface),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            '新報',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          actions: [
            Consumer(
              builder: (context, ref, child) {
                final bookmarkedNewsIds = ref.watch(bookmarkedNewsIdsProvider);
                final isBookmarked = bookmarkedNewsIds.contains(
                  _news?.newsId ?? '',
                );

                return IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: isBookmarked ? Colors.amber : colorScheme.onSurface,
                  ),
                  onPressed: () async {
                    if (_news != null) {
                      final bookmarkNotifier = ref.read(
                        bookmarkedNewsIdsProvider.notifier,
                      );
                      await bookmarkNotifier.toggleBookmark(_news!.newsId);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isBookmarked
                                ? 'Bookmark removed'
                                : 'Article bookmarked',
                          ),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
            Tooltip(
              message: 'Open in NHK',
              child: IconButton(
                icon: Icon(Icons.open_in_new, color: colorScheme.onSurface),
                onPressed: () async {
                  try {
                    final nhkUrl =
                        'https://www3.nhk.or.jp/news/easy/${_news?.newsId}/${_news?.newsId}.html';
                    final uri = Uri.parse(nhkUrl);

                    final result =
                        await launchUrl(uri, mode: LaunchMode.platformDefault);

                    if (!result) {
                      throw Exception('Failed to launch URL');
                    }
                  } catch (e) {
                    print('Error launching URL: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Failed to open in NHK: ${e.toString()}'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
            IconButton(
              icon: Icon(Icons.share, color: colorScheme.onSurface),
              onPressed: () async {
                try {
                  final shareText =
                      '${_news?.title}\n\nRead more NHK Easy news with this app!';
                  await SharePlus.instance.share(
                    ShareParams(
                      text: shareText,
                      subject: 'NHK Easy News: ${_news?.title}',
                    ),
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to share: ${e.toString()}'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
        body: Stack(
          children: <Widget>[
            _buildNewsBody(),
            if (_showDictionary) _buildDictionary(),
          ],
        ),
        floatingActionButton: _hasAudio() ? _buildAudioPlayer() : null,
      ),
    );
  }

  bool _hasAudio() {
    return _news?.m3u8Url != null && _news?.m3u8Url != '';
  }

  Widget _buildNewsBody() {
    return CustomScrollView(
      slivers: [
        if (_news?.imageUrl != null && _news!.imageUrl.isNotEmpty)
          SliverToBoxAdapter(child: _buildHeroImage()),
        SliverPadding(
          padding: EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildArticleHeader(),
              SizedBox(height: 24),
              _buildArticleBody(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroImage() {
    return Container(
      width: double.infinity,
      height: 250,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: Image.network(
              _news!.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: Icon(
                    Icons.image_not_supported,
                    size: 64,
                    color: Colors.grey[600],
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7)
                  ],
                ),
              ),
              height: 80,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleHeader() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fontScale = ref.watch(fontSizeProvider).scale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RubyTextWidget(
          text: _news!.titleWithRuby,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
            height: 1.3,
            fontSize:
                (theme.textTheme.headlineMedium?.fontSize ?? 24) * fontScale,
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Icon(
              Icons.access_time,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: 8),
            Text(
              _formatPublishedDate(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize:
                    (theme.textTheme.bodyMedium?.fontSize ?? 14) * fontScale,
              ),
            ),
            Spacer(),
            if (_hasAudio())
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.volume_up,
                      size: 16,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Audio Available',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildArticleBody() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fontScale = ref.watch(fontSizeProvider).scale;

    final bodyText = _parseHtmlBody(_news!.body);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: bodyText.map((textBlock) {
        if (textBlock is String) {
          return Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              textBlock,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
                height: 1.6,
                fontSize:
                    (theme.textTheme.bodyLarge?.fontSize ?? 16) * fontScale,
              ),
            ),
          );
        } else if (textBlock is List<Map<String, dynamic>>) {
          return _buildFormattedText(textBlock, theme, colorScheme);
        }
        return SizedBox.shrink();
      }).toList(),
    );
  }

  List<dynamic> _parseHtmlBody(String htmlBody) {
    final List<dynamic> result = [];

    final paragraphs =
        htmlBody.split(RegExp(r'</?p[^>]*>')).where((p) => p.trim().isNotEmpty);

    for (String paragraph in paragraphs) {
      if (paragraph.trim().isEmpty) continue;

      final dicWordPattern = RegExp(
        r'<span[^>]*class="dicWin"[^>]*id="([^"]*)"[^>]*>(.*?)</span>',
      );
      final matches = dicWordPattern.allMatches(paragraph);

      if (matches.isEmpty) {
        result.add(_cleanHtml(paragraph));
      } else {
        final textParts = <Map<String, dynamic>>[];
        int lastIndex = 0;

        for (final match in matches) {
          if (match.start > lastIndex) {
            final beforeText = paragraph.substring(lastIndex, match.start);
            if (beforeText.trim().isNotEmpty) {
              textParts.add({'type': 'text', 'text': _cleanHtml(beforeText)});
            }
          }

          textParts.add({
            'type': 'dictionary',
            'id': match.group(1),
            'text': _cleanHtml(match.group(2) ?? ''),
          });

          lastIndex = match.end;
        }

        if (lastIndex < paragraph.length) {
          final afterText = paragraph.substring(lastIndex);
          if (afterText.trim().isNotEmpty) {
            textParts.add({'type': 'text', 'text': _cleanHtml(afterText)});
          }
        }

        result.add(textParts);
      }
    }

    return result;
  }

  String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .trim();
  }

  Widget _buildFormattedText(
    List<Map<String, dynamic>> textParts,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final List<TextSpan> spans = [];

    for (final part in textParts) {
      if (part['type'] == 'text') {
        spans.add(
          TextSpan(
            text: part['text'],
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
              height: 1.6,
            ),
          ),
        );
      } else if (part['type'] == 'dictionary') {
        spans.add(
          TextSpan(
            text: part['text'],
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.primary,
              height: 1.6,
              decoration: TextDecoration.underline,
              decorationColor: colorScheme.primary,
            ),
          ),
        );
      }
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTapDown: (details) {
          // Handle tap on dictionary words

          for (final part in textParts) {
            if (part['type'] == 'dictionary') {
              _showWordDefinition(part['id']);
              break;
            }
          }
        },
        child: RichText(text: TextSpan(children: spans)),
      ),
    );
  }

  void _showWordDefinition(String wordId) {
    final word = _words.firstWhere(
      (word) => word.idInNews == wordId,
      orElse: () => Word(),
    );

    if (word.name.isNotEmpty) {
      setState(() {
        _currentWord = word;
        _showDictionary = true;
      });
    }
  }

  String _formatPublishedDate() {
    if (_news?.publishedAtUtc == null || _news!.publishedAtUtc.isEmpty) {
      return 'Published recently';
    }

    try {
      final date = DateTime.parse(_news!.publishedAtUtc);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return 'Published ${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else if (difference.inHours > 0) {
        return 'Published ${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inMinutes > 0) {
        return 'Published ${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else {
        return 'Published just now';
      }
    } catch (e) {
      return 'Published recently';
    }
  }

  Widget _buildDictionary() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.book, color: colorScheme.onPrimaryContainer),
                    SizedBox(width: 8),
                    Text(
                      'Dictionary',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: _buildWordDefinitions(_currentWord),
              ),
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _currentWord = null;
                          _showDictionary = false;
                        });
                      },
                      child: Text('Close'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWordDefinitions(Word? word) {
    if (word == null) {
      return Container();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final definitions = word.definitions
        .asMap()
        .entries
        .map(
          (entry) => Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${entry.key + 1}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.value.definition,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          word.name,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 16),
        ...definitions,
      ],
    );
  }

  Widget _buildAudioPlayer() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FloatingActionButton.extended(
      onPressed: () async {
        if (_audioPlayer?.playing ?? false) {
          _audioPlayer?.pause().catchError((error, stackTrace) {
            ErrorReporter.reportError(error, stackTrace);
          });
        } else {
          _audioPlayer?.play().catchError((error, stackTrace) {
            ErrorReporter.reportError(error, stackTrace);
          });
        }

        setState(() {
          _isPlaying = _audioPlayer?.playing ?? false;
        });
      },
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
      label: Text(_isPlaying ? 'Pause' : 'Play Audio'),
    );
  }
}
