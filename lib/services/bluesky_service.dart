import 'package:bluesky/bluesky.dart' as bsky;
import 'package:bluesky/atproto.dart' as atproto;
import 'package:bluesky/app_bsky_feed_defs.dart' as feed_defs;
import 'package:bluesky/app_bsky_embed_defs.dart' as embed_defs;
import 'package:bluesky/app_bsky_embed_recordwithmedia.dart';
import 'package:bluesky/com_atproto_repo_strongref.dart' as repo;
import 'package:atproto_core/atproto_core.dart' as core;
import '../models/image_post.dart';

/// Result of fetching a page of image posts from the timeline.
class FeedPage {
  final List<ImagePost> posts;
  final String? cursor;

  const FeedPage({required this.posts, this.cursor});
}

/// Wraps the bluesky SDK to provide a testable API surface.
abstract class BlueskyService {
  /// Authenticate with handle + app password. Returns the session.
  Future<core.Session> login(String handle, String appPassword);

  /// Fetch a page of the home timeline. Pass [cursor] for pagination.
  Future<FeedPage> getTimeline({int limit = 50, String? cursor});

  /// Fetch a page of a specific feed generator.
  Future<FeedPage> getFeed({
    required String generatorUri,
    int limit = 50,
    String? cursor,
  });

  /// Like a post. Returns the AT URI of the like record.
  Future<String> likePost(String uri, String cid);

  /// Remove a like by its AT URI record key.
  Future<void> unlikePost(String likeUri);
}

class BlueskyServiceImpl implements BlueskyService {
  bsky.Bluesky? _client;

  @override
  Future<core.Session> login(String handle, String appPassword) async {
    final session = await atproto.createSession(
      identifier: handle,
      password: appPassword,
    );
    _client = bsky.Bluesky.fromSession(session.data);
    return session.data;
  }

  @override
  Future<FeedPage> getTimeline({int limit = 50, String? cursor}) async {
    final client = _client;
    if (client == null) throw StateError('Not authenticated');

    final response = await client.feed.getTimeline(
      limit: limit,
      cursor: cursor,
    );

    return _parseFeedItems(response.data.feed, response.data.cursor);
  }

  @override
  Future<FeedPage> getFeed({
    required String generatorUri,
    int limit = 50,
    String? cursor,
  }) async {
    final client = _client;
    if (client == null) throw StateError('Not authenticated');

    final response = await client.feed.getFeed(
      feed: core.AtUri.parse(generatorUri),
      limit: limit,
      cursor: cursor,
    );

    return _parseFeedItems(response.data.feed, response.data.cursor);
  }

  FeedPage _parseFeedItems(
    List<feed_defs.FeedViewPost> items,
    String? cursor,
  ) {
    final imagePosts = <ImagePost>[];
    for (final item in items) {
      final post = _extractImagePost(item);
      if (post != null) imagePosts.add(post);
    }
    return FeedPage(posts: imagePosts, cursor: cursor);
  }

  @override
  Future<String> likePost(String uri, String cid) async {
    final client = _client;
    if (client == null) throw StateError('Not authenticated');

    final result = await client.feed.like.create(
      subject: repo.RepoStrongRef(
        uri: core.AtUri.parse(uri),
        cid: cid,
      ),
    );
    return result.data.uri.toString();
  }

  @override
  Future<void> unlikePost(String likeUri) async {
    final client = _client;
    if (client == null) throw StateError('Not authenticated');

    final atUri = core.AtUri.parse(likeUri);
    await client.feed.like.delete(rkey: atUri.rkey);
  }

  /// Extract an [ImagePost] from a feed item, returning null if it has no images.
  ImagePost? _extractImagePost(feed_defs.FeedViewPost item) {
    final post = item.post;
    final embed = post.embed;
    if (embed == null) return null;

    final images = <PostImage>[];

    embed.when(
      embedImagesView: (data) {
        for (final img in data.images) {
          images.add(PostImage(
            thumb: img.thumb,
            fullsize: img.fullsize,
            alt: img.alt,
            aspectRatio: _aspectRatio(img.aspectRatio),
          ));
        }
      },
      embedExternalView: (_) {},
      embedRecordView: (_) {},
      embedRecordWithMediaView: (data) {
        // Use Dart 3 pattern matching on the sealed media union.
        final media = data.media;
        if (media is UEmbedRecordWithMediaViewMediaEmbedImagesView) {
          for (final img in media.data.images) {
            images.add(PostImage(
              thumb: img.thumb,
              fullsize: img.fullsize,
              alt: img.alt,
              aspectRatio: _aspectRatio(img.aspectRatio),
            ));
          }
        }
      },
      embedVideoView: (_) {},
      unknown: (_) {},
    );

    if (images.isEmpty) return null;

    final viewer = post.viewer;
    final viewerLike = viewer?.like;
    final isLiked = viewerLike != null;

    return ImagePost(
      uri: post.uri.toString(),
      cid: post.cid,
      authorHandle: post.author.handle,
      authorDisplayName: post.author.displayName ?? post.author.handle,
      authorAvatar: post.author.avatar ?? '',
      text: (post.record['text'] as String?) ?? '',
      images: images,
      likeCount: post.likeCount ?? 0,
      isLiked: isLiked,
      viewerLikeUri: viewerLike?.toString(),
    );
  }

  double _aspectRatio(embed_defs.AspectRatio? ratio) {
    if (ratio == null) return 1.0;
    if (ratio.height == 0) return 1.0;
    return ratio.width / ratio.height;
  }
}
