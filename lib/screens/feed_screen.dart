import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/feed_state.dart';
import '../providers/auth_provider.dart';
import '../providers/feed_provider.dart';
import '../providers/settings_provider.dart';
import '../services/image_cache_service.dart';
import '../widgets/post_card.dart';
import 'settings_screen.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _scrollController = ScrollController();

  /// Highest post index whose images have been prefetched.
  int _prefetchedUpTo = -1;

  /// How many posts ahead of the last visible item to prefetch.
  static const _prefetchAhead = 15;

  @override
  void initState() {
    super.initState();
    // Load feed on first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(feedProvider.notifier).loadFeed();
      // Prefetch upcoming images whenever feed data changes.
      ref.listenManual(feedProvider, (_, __) => _prefetchUpcoming());
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      ref.read(feedProvider.notifier).loadMore();
    }
    _prefetchUpcoming();
  }

  /// Prefetch thumbnail images for posts that are about to scroll into view.
  void _prefetchUpcoming() {
    final posts = ref.read(feedProvider).posts;
    if (posts.isEmpty) return;

    // Estimate which post index is currently at the bottom of the viewport.
    // Each card is roughly 250px tall on average in a masonry grid.
    final scrollPos = _scrollController.position.pixels +
        _scrollController.position.viewportDimension;
    final estimatedLastVisible = (scrollPos / 250).ceil();

    final target = (estimatedLastVisible + _prefetchAhead)
        .clamp(0, posts.length - 1);

    if (target <= _prefetchedUpTo) return;

    final start = _prefetchedUpTo + 1;
    _prefetchedUpTo = target;

    for (int i = start; i <= target; i++) {
      for (final img in posts[i].images) {
        _warmCache(img.thumb);
      }
    }
  }

  /// Trigger a cache download without building a widget.
  void _warmCache(String url) {
    CachedNetworkImageProvider(url, cacheManager: ImageCacheManager.instance)
        .resolve(const ImageConfiguration());
  }

  void _selectFeed(FeedChoice feed) {
    ref.read(selectedFeedProvider.notifier).select(feed);
    _prefetchedUpTo = -1;
    // Scroll to top and reload.
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    ref.read(feedProvider.notifier).loadFeed();
  }

  /// Calculate column count based on screen width, unless overridden.
  int _columnCount(double width, int? override) {
    if (override != null && override > 0) return override;
    if (width >= 1200) return 5;
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(feedProvider);
    final columnOverride = ref.watch(columnOverrideProvider);
    final selectedFeed = ref.watch(selectedFeedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluesky Images'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Feed selector chips.
          _FeedSelector(
            selected: selectedFeed,
            onSelected: _selectFeed,
          ),
          // Feed content.
          Expanded(child: _buildBody(feed, columnOverride)),
        ],
      ),
    );
  }

  Widget _buildBody(feed, int? columnOverride) {
    if (feed.isLoading && feed.posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (feed.error != null && feed.posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(feed.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.read(feedProvider.notifier).loadFeed(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (feed.posts.isEmpty) {
      return const Center(
        child: Text('No image posts found in this feed.'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(feedProvider.notifier).loadFeed(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = _columnCount(constraints.maxWidth, columnOverride);
          return CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverMasonryGrid.count(
                crossAxisCount: columns,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childCount: feed.posts.length,
                itemBuilder: (context, index) {
                  return PostCard(
                    post: feed.posts[index],
                    postIndex: index,
                  );
                },
              ),
              if (feed.isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Horizontal row of feed choice chips.
class _FeedSelector extends StatelessWidget {
  final FeedChoice selected;
  final ValueChanged<FeedChoice> onSelected;

  const _FeedSelector({required this.selected, required this.onSelected});

  static const _icons = {
    'following': Icons.people,
    'discover': Icons.explore,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: FeedChoice.defaults.map((feed) {
            final isSelected = feed == selected;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                key: Key('feed_chip_${feed.id}'),
                avatar: Icon(
                  _icons[feed.id] ?? Icons.rss_feed,
                  size: 18,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : null,
                ),
                label: Text(feed.label),
                selected: isSelected,
                onSelected: (_) => onSelected(feed),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
