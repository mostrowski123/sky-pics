import 'package:mocktail/mocktail.dart';
import 'package:atproto_core/atproto_core.dart' as core;
import 'package:sky_pics/services/bluesky_service.dart';
import 'package:sky_pics/services/credential_service.dart';
import 'package:sky_pics/models/image_post.dart';

/// Mock for the BlueskyService abstraction.
class MockBlueskyService extends Mock implements BlueskyService {}

/// Mock for the CredentialService abstraction.
class MockCredentialService extends Mock implements CredentialService {}

/// Creates a fake [core.Session] for testing.
core.Session fakeSession() {
  return const core.Session(
    accessJwt: 'test-access-jwt',
    refreshJwt: 'test-refresh-jwt',
    handle: 'testuser.bsky.social',
    did: 'did:plc:testuser123',
  );
}

/// Creates a test [ImagePost].
ImagePost testImagePost({
  String uri = 'at://did:plc:abc/app.bsky.feed.post/123',
  String cid = 'bafyreiabc123',
  String authorHandle = 'alice.bsky.social',
  String authorDisplayName = 'Alice',
  String authorAvatar = 'https://example.com/avatar.jpg',
  String text = 'Check out this photo!',
  int imageCount = 1,
  int likeCount = 5,
  bool isLiked = false,
  String? viewerLikeUri,
}) {
  return ImagePost(
    uri: uri,
    cid: cid,
    authorHandle: authorHandle,
    authorDisplayName: authorDisplayName,
    authorAvatar: authorAvatar,
    text: text,
    images: List.generate(
      imageCount,
      (i) => PostImage(
        thumb: 'https://example.com/thumb_$i.jpg',
        fullsize: 'https://example.com/full_$i.jpg',
        alt: 'Image $i description',
        aspectRatio: 1.5,
      ),
    ),
    likeCount: likeCount,
    isLiked: isLiked,
    viewerLikeUri: viewerLikeUri,
  );
}

/// Creates a test [FeedPage].
FeedPage testFeedPage({
  int postCount = 5,
  String? cursor = 'next-cursor-abc',
}) {
  return FeedPage(
    posts: List.generate(postCount, (i) => testImagePost(
      uri: 'at://did:plc:abc/app.bsky.feed.post/$i',
      cid: 'bafyrei$i',
      authorHandle: 'user$i.bsky.social',
      authorDisplayName: 'User $i',
    )),
    cursor: cursor,
  );
}
