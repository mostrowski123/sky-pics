import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/feed_state.dart';
import '../models/image_post.dart';
import '../services/bluesky_service.dart';
import 'service_providers.dart';

/// Tracks which feed is currently selected.
class SelectedFeedNotifier extends Notifier<FeedChoice> {
  @override
  FeedChoice build() => FeedChoice.following;

  void select(FeedChoice feed) {
    if (state == feed) return;
    state = feed;
  }
}

final selectedFeedProvider =
    NotifierProvider<SelectedFeedNotifier, FeedChoice>(
  SelectedFeedNotifier.new,
);

/// Manages the image feed state with pagination using Riverpod v3 Notifier.
class FeedNotifier extends Notifier<FeedState> {
  @override
  FeedState build() => const FeedState();

  /// Fetch a page using the correct API based on the selected feed.
  Future<FeedPage> _fetchPage({int limit = 50, String? cursor}) {
    final service = ref.read(blueskyServiceProvider);
    final feed = ref.read(selectedFeedProvider);

    if (feed.isTimeline) {
      return service.getTimeline(limit: limit, cursor: cursor);
    }
    return service.getFeed(
      generatorUri: feed.generatorUri!,
      limit: limit,
      cursor: cursor,
    );
  }

  /// Load the first page of the feed (also used for pull-to-refresh).
  Future<void> loadFeed() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final page = await _fetchPage();
      state = FeedState(
        posts: page.posts,
        cursor: page.cursor,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load the next page (infinite scroll).
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      final page = await _fetchPage(cursor: state.cursor);
      state = state.copyWith(
        posts: [...state.posts, ...page.posts],
        cursor: page.cursor,
        isLoadingMore: false,
        clearCursor: page.cursor == null,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  /// Toggle the like state for a post at the given index.
  Future<void> toggleLike(int index) async {
    if (index < 0 || index >= state.posts.length) return;
    final post = state.posts[index];
    final service = ref.read(blueskyServiceProvider);

    // Optimistic update.
    final updatedPost = post.copyWith(
      isLiked: !post.isLiked,
      likeCount: post.isLiked ? post.likeCount - 1 : post.likeCount + 1,
    );
    _updatePostAt(index, updatedPost);

    try {
      if (post.isLiked && post.viewerLikeUri != null) {
        await service.unlikePost(post.viewerLikeUri!);
        _updatePostAt(
          index,
          updatedPost.copyWith(viewerLikeUri: ''),
        );
      } else {
        final likeUri = await service.likePost(post.uri, post.cid);
        _updatePostAt(
          index,
          updatedPost.copyWith(viewerLikeUri: likeUri),
        );
      }
    } catch (_) {
      // Revert on failure.
      _updatePostAt(index, post);
    }
  }

  void _updatePostAt(int index, ImagePost post) {
    final posts = List<ImagePost>.from(state.posts);
    posts[index] = post;
    state = state.copyWith(posts: posts);
  }
}

final feedProvider = NotifierProvider<FeedNotifier, FeedState>(
  FeedNotifier.new,
);
