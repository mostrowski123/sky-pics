import 'image_post.dart';

/// A feed the user can choose to view.
class FeedChoice {
  final String id;
  final String label;
  final String? generatorUri;

  const FeedChoice({
    required this.id,
    required this.label,
    this.generatorUri,
  });

  /// Home timeline (people you follow).
  static const following = FeedChoice(id: 'following', label: 'Following');

  /// The official Bluesky "Discover" feed.
  static const discover = FeedChoice(
    id: 'discover',
    label: 'Discover',
    generatorUri:
        'at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.generator/whats-hot',
  );

  static const defaults = [following, discover];

  bool get isTimeline => generatorUri == null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FeedChoice && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Represents the state of the image feed.
class FeedState {
  final List<ImagePost> posts;
  final String? cursor;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  const FeedState({
    this.posts = const [],
    this.cursor,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  bool get hasMore => cursor != null;

  FeedState copyWith({
    List<ImagePost>? posts,
    String? cursor,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearCursor = false,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      cursor: clearCursor ? null : (cursor ?? this.cursor),
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }
}
