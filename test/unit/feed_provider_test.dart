import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_pics/models/feed_state.dart';
import 'package:sky_pics/providers/feed_provider.dart';
import 'package:sky_pics/providers/service_providers.dart';
import 'package:sky_pics/services/bluesky_service.dart';
import '../helpers/test_helpers.dart';

void main() {
  late MockBlueskyService mockService;
  late ProviderContainer container;

  setUp(() {
    mockService = MockBlueskyService();
    container = ProviderContainer(
      overrides: [
        blueskyServiceProvider.overrideWithValue(mockService),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('FeedNotifier', () {
    test('initial state is empty with no loading', () {
      final state = container.read(feedProvider);
      expect(state.posts, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.cursor, isNull);
    });

    test('loadFeed populates posts and cursor', () async {
      final page = testFeedPage(postCount: 3, cursor: 'cursor-1');
      when(() => mockService.getTimeline(limit: 50))
          .thenAnswer((_) async => page);

      await container.read(feedProvider.notifier).loadFeed();

      final state = container.read(feedProvider);
      expect(state.posts.length, 3);
      expect(state.cursor, 'cursor-1');
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('loadFeed sets error on failure', () async {
      when(() => mockService.getTimeline(limit: 50))
          .thenThrow(Exception('API error'));

      await container.read(feedProvider.notifier).loadFeed();

      final state = container.read(feedProvider);
      expect(state.error, isNotNull);
      expect(state.posts, isEmpty);
    });

    test('loadMore appends posts from next page', () async {
      final page1 = testFeedPage(postCount: 3, cursor: 'cursor-1');
      when(() => mockService.getTimeline(limit: 50))
          .thenAnswer((_) async => page1);
      await container.read(feedProvider.notifier).loadFeed();
      expect(container.read(feedProvider).posts.length, 3);

      final page2 = testFeedPage(postCount: 2, cursor: null);
      when(() => mockService.getTimeline(limit: 50, cursor: 'cursor-1'))
          .thenAnswer((_) async => page2);
      await container.read(feedProvider.notifier).loadMore();

      final state = container.read(feedProvider);
      expect(state.posts.length, 5);
      expect(state.hasMore, isFalse);
    });

    test('loadMore does nothing when already loading more', () async {
      final page = testFeedPage(postCount: 2, cursor: 'c1');
      when(() => mockService.getTimeline(limit: 50))
          .thenAnswer((_) async => page);
      await container.read(feedProvider.notifier).loadFeed();

      when(() => mockService.getTimeline(limit: 50, cursor: 'c1'))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return testFeedPage(postCount: 1, cursor: null);
      });

      final f1 = container.read(feedProvider.notifier).loadMore();
      container.read(feedProvider.notifier).loadMore();
      await f1;

      verify(() => mockService.getTimeline(limit: 50, cursor: 'c1')).called(1);
    });

    test('loadMore does nothing when no more pages', () async {
      final page = testFeedPage(postCount: 2, cursor: null);
      when(() => mockService.getTimeline(limit: 50))
          .thenAnswer((_) async => page);
      await container.read(feedProvider.notifier).loadFeed();

      // loadFeed called getTimeline once. loadMore should not call it again
      // since cursor is null (no more pages).
      await container.read(feedProvider.notifier).loadMore();

      // Total calls should be exactly 1 (from loadFeed only).
      verify(() => mockService.getTimeline(limit: 50)).called(1);
    });

    test('toggleLike performs optimistic update', () async {
      final page = testFeedPage(postCount: 1);
      when(() => mockService.getTimeline(limit: 50))
          .thenAnswer((_) async => page);
      await container.read(feedProvider.notifier).loadFeed();

      when(() => mockService.likePost(any(), any()))
          .thenAnswer((_) async => 'at://did:plc:abc/app.bsky.feed.like/xyz');

      await container.read(feedProvider.notifier).toggleLike(0);

      final post = container.read(feedProvider).posts[0];
      expect(post.isLiked, isTrue);
      expect(post.likeCount, 6);
    });

    test('toggleLike reverts on failure', () async {
      final page = testFeedPage(postCount: 1);
      when(() => mockService.getTimeline(limit: 50))
          .thenAnswer((_) async => page);
      await container.read(feedProvider.notifier).loadFeed();

      when(() => mockService.likePost(any(), any()))
          .thenThrow(Exception('Network error'));

      await container.read(feedProvider.notifier).toggleLike(0);

      final post = container.read(feedProvider).posts[0];
      expect(post.isLiked, isFalse);
      expect(post.likeCount, 5);
    });

    test('toggleLike unlikes when already liked', () async {
      final likedPost = testImagePost(
        isLiked: true,
        likeCount: 10,
        viewerLikeUri: 'at://did:plc:abc/app.bsky.feed.like/existing',
      );
      final page = FeedPage(posts: [likedPost], cursor: null);
      when(() => mockService.getTimeline(limit: 50))
          .thenAnswer((_) async => page);
      await container.read(feedProvider.notifier).loadFeed();

      when(() => mockService.unlikePost(any())).thenAnswer((_) async {});

      await container.read(feedProvider.notifier).toggleLike(0);

      final post = container.read(feedProvider).posts[0];
      expect(post.isLiked, isFalse);
      expect(post.likeCount, 9);
    });

    test('toggleLike ignores invalid index', () async {
      final page = testFeedPage(postCount: 1);
      when(() => mockService.getTimeline(limit: 50))
          .thenAnswer((_) async => page);
      await container.read(feedProvider.notifier).loadFeed();

      await container.read(feedProvider.notifier).toggleLike(-1);
      await container.read(feedProvider.notifier).toggleLike(99);

      verifyNever(() => mockService.likePost(any(), any()));
    });

    test('loadFeed refreshes and replaces posts', () async {
      final page1 = testFeedPage(postCount: 3, cursor: 'c1');
      when(() => mockService.getTimeline(limit: 50))
          .thenAnswer((_) async => page1);
      await container.read(feedProvider.notifier).loadFeed();
      expect(container.read(feedProvider).posts.length, 3);

      final page2 = testFeedPage(postCount: 2, cursor: 'c2');
      when(() => mockService.getTimeline(limit: 50))
          .thenAnswer((_) async => page2);
      await container.read(feedProvider.notifier).loadFeed();
      expect(container.read(feedProvider).posts.length, 2);
    });
  });

  group('Feed switching', () {
    test('selecting Discover feed calls getFeed', () async {
      // Switch to Discover feed.
      container.read(selectedFeedProvider.notifier).select(FeedChoice.discover);
      expect(container.read(selectedFeedProvider), FeedChoice.discover);

      final page = testFeedPage(postCount: 4, cursor: 'disc-cursor');
      when(() => mockService.getFeed(
            generatorUri: FeedChoice.discover.generatorUri!,
            limit: 50,
          )).thenAnswer((_) async => page);

      await container.read(feedProvider.notifier).loadFeed();

      verify(() => mockService.getFeed(
            generatorUri: FeedChoice.discover.generatorUri!,
            limit: 50,
          )).called(1);
      verifyNever(() => mockService.getTimeline(limit: any(named: 'limit')));
      expect(container.read(feedProvider).posts.length, 4);
    });

    test('switching back to Following uses getTimeline', () async {
      container.read(selectedFeedProvider.notifier).select(FeedChoice.discover);
      container.read(selectedFeedProvider.notifier).select(FeedChoice.following);
      expect(container.read(selectedFeedProvider), FeedChoice.following);

      final page = testFeedPage(postCount: 2);
      when(() => mockService.getTimeline(limit: 50))
          .thenAnswer((_) async => page);

      await container.read(feedProvider.notifier).loadFeed();

      verify(() => mockService.getTimeline(limit: 50)).called(1);
    });

    test('selecting same feed does not change state', () {
      container.read(selectedFeedProvider.notifier).select(FeedChoice.following);
      // Should remain the same reference.
      expect(container.read(selectedFeedProvider), FeedChoice.following);
    });
  });
}
