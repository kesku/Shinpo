import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinpo/model/news.dart';
import 'package:shinpo/providers/search_provider.dart';
import 'package:shinpo/widget/news_detail.dart';
import 'package:shinpo/widget/search_filters.dart';
import 'package:shinpo/widget/ruby_text_widget.dart';
import 'package:shinpo/providers/furigana_provider.dart';
import 'package:shinpo/widget/audio_chip.dart';
import 'package:shinpo/util/date_locale_utils.dart';
import 'package:shinpo/util/html_utils.dart';
import 'package:shinpo/util/navigation.dart';

class SearchScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 300);
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      ref.read(searchProvider.notifier).clearSearch();
      return;
    }

    _debouncer.run(() {
      if (_startDate != null && _endDate != null) {
        ref
            .read(searchProvider.notifier)
            .searchInDateRange(query, _startDate!, _endDate!);
      } else {
        ref.read(searchProvider.notifier).search(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search articles...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          style: TextStyle(
            fontSize: 18,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
              },
              tooltip: 'Clear search',
            ),
        ],
      ),
      body: Column(
        children: [
          if (!searchState.hasSearched)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (searchState.recentSearches.isNotEmpty) ...[
                    Row(
                      children: [
                        Text(
                          'Recent searches',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        Spacer(),
                        TextButton(
                          onPressed: () {
                            ref
                                .read(searchProvider.notifier)
                                .clearRecentSearches();
                          },
                          child: Text('Clear all'),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    ...(searchState.recentSearches
                        .map((recentSearch) => ListTile(
                              dense: true,
                              leading: Icon(Icons.history, size: 20),
                              title: Text(
                                recentSearch,
                                style: TextStyle(fontSize: 14),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.close, size: 16),
                                onPressed: () {
                                  ref
                                      .read(searchProvider.notifier)
                                      .removeRecentSearch(recentSearch);
                                },
                              ),
                              onTap: () {
                                _searchController.text = recentSearch;
                                if (_startDate != null && _endDate != null) {
                                  ref
                                      .read(searchProvider.notifier)
                                      .searchInDateRange(
                                          recentSearch, _startDate!, _endDate!);
                                } else {
                                  ref
                                      .read(searchProvider.notifier)
                                      .search(recentSearch);
                                }
                              },
                            ))).toList(),
                    SizedBox(height: 16),
                  ],
                  if (searchState.suggestions.isNotEmpty) ...[
                    Text(
                      'Suggestions',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    SizedBox(height: 8),
                    ...(searchState.suggestions.map((suggestion) => ListTile(
                          dense: true,
                          leading: Icon(Icons.search, size: 20),
                          title: Text(
                            suggestion,
                            style: TextStyle(fontSize: 14),
                          ),
                          onTap: () {
                            _searchController.text = suggestion;
                            if (_startDate != null && _endDate != null) {
                              ref
                                  .read(searchProvider.notifier)
                                  .searchInDateRange(
                                      suggestion, _startDate!, _endDate!);
                            } else {
                              ref
                                  .read(searchProvider.notifier)
                                  .search(suggestion);
                            }
                          },
                        ))).toList(),
                  ],
                ],
              ),
            ),
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final searchState = ref.watch(searchProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (searchState.isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator.adaptive(),
            SizedBox(height: 16),
            Text(
              'Searching...',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    if (!searchState.hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 16),
            Text(
              'Search for articles',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            SizedBox(height: 8),
            Text(
              'Type keywords to find news articles',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    if (searchState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            SizedBox(height: 16),
            Text(
              'Search error',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colorScheme.error,
                  ),
            ),
            SizedBox(height: 8),
            Text(
              searchState.error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (searchState.query != null) {
                  if (_startDate != null && _endDate != null) {
                    ref.read(searchProvider.notifier).searchInDateRange(
                        searchState.query!, _startDate!, _endDate!);
                  } else {
                    ref
                        .read(searchProvider.notifier)
                        .search(searchState.query!);
                  }
                }
              },
              child: Text('Try again'),
            ),
          ],
        ),
      );
    }

    if (searchState.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 16),
            Text(
              'No results found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            SizedBox(height: 8),
            Text(
              'Try different keywords',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        SearchFilters(
          onFiltersChanged: (startDate, endDate) {
            setState(() {
              _startDate = startDate;
              _endDate = endDate;
            });

            if (searchState.query != null && searchState.query!.isNotEmpty) {
              if (startDate != null && endDate != null) {
                ref
                    .read(searchProvider.notifier)
                    .searchInDateRange(searchState.query!, startDate, endDate);
              } else {
                ref.read(searchProvider.notifier).search(searchState.query!);
              }
            }
          },
          initialStartDate: _startDate,
          initialEndDate: _endDate,
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                '${searchState.results.length} result${searchState.results.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Spacer(),
              if (searchState.query?.isNotEmpty == true)
                Text(
                  'for "${searchState.query}"',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 8),
            itemCount: searchState.results.length,
            itemBuilder: (context, index) {
              return _buildSearchResultCard(searchState.results[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultCard(News news) {
    final publishedDate = DateTime.parse(news.publishedAtUtc).toLocal();

    return Card(
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
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: CircularProgressIndicator.adaptive(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
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
                  RubyTextWidget(
                    text: news.titleWithRuby,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                    showRuby: ref.watch(furiganaProvider),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  if (news.body.isNotEmpty) ...[
                    Builder(builder: (context) {
                      final query = ref.read(searchProvider).query ?? '';
                      final normalStyle = Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ) ??
                          TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant);
                      final highlightStyle = normalStyle.copyWith(
                        backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                        color: Theme.of(context).colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w600,
                      );
                      return RichText(
                        text: _buildHighlightedSnippet(
                          news.body,
                          query,
                          normalStyle,
                          highlightStyle,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      );
                    }),
                    SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(width: 4),
                      Text(
                        DateLocaleUtils.formatAbsolute(context, publishedDate),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      Spacer(),
                      if (news.m3u8Url.isNotEmpty) const AudioChip(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextSpan _buildHighlightedSnippet(
    String html,
    String query,
    TextStyle normal,
    TextStyle highlight,
  ) {
    final plain = HtmlUtils.stripHtml(html);
    if (query.trim().isEmpty || plain.isEmpty) {
      return TextSpan(text: plain, style: normal);
    }
    final q = query.trim();
    final idx = plain.toLowerCase().indexOf(q.toLowerCase());
    final window = 90;
    final start = idx == -1
        ? 0
        : (idx - window ~/ 2).clamp(0, (plain.length - 1).clamp(0, plain.length));
    final end = idx == -1
        ? (plain.length < window ? plain.length : window)
        : (idx + q.length + window ~/ 2).clamp(0, plain.length);
    final snippet = plain.substring(start, end);

    if (idx == -1) {
      return TextSpan(text: snippet, style: normal);
    }

    final localIdx = snippet.toLowerCase().indexOf(q.toLowerCase());
    final before = snippet.substring(0, localIdx);
    final match = snippet.substring(localIdx, localIdx + q.length);
    final after = snippet.substring(localIdx + q.length);

    final spans = <InlineSpan>[];
    if (start > 0) spans.add(const TextSpan(text: '…'));
    if (before.isNotEmpty) spans.add(TextSpan(text: before, style: normal));
    spans.add(TextSpan(text: match, style: highlight));
    if (after.isNotEmpty) spans.add(TextSpan(text: after, style: normal));
    if (end < plain.length) spans.add(const TextSpan(text: '…'));
    return TextSpan(children: spans, style: normal);
  }
}

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
