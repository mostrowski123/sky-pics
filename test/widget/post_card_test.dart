import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_pics/widgets/post_card.dart';
import 'package:sky_pics/providers/service_providers.dart';
import '../helpers/test_helpers.dart';

void main() {
  late MockBlueskyService mockService;

  setUp(() {
    mockService = MockBlueskyService();
  });

  Widget buildPostCard({
    required int postIndex,
    int imageCount = 1,
    bool isLiked = false,
    int likeCount = 5,
  }) {
    final post = testImagePost(
      imageCount: imageCount,
      isLiked: isLiked,
      likeCount: likeCount,
      viewerLikeUri: isLiked ? 'at://like/uri' : null,
    );

    return ProviderScope(
      overrides: [
        blueskyServiceProvider.overrideWithValue(mockService),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            child: PostCard(post: post, postIndex: postIndex),
          ),
        ),
      ),
    );
  }

  group('PostCard', () {
    testWidgets('renders author display name', (tester) async {
      await tester.pumpWidget(buildPostCard(postIndex: 0));
      await tester.pump();

      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('renders like button with count', (tester) async {
      await tester.pumpWidget(
          buildPostCard(postIndex: 0, likeCount: 42));
      await tester.pump();

      expect(find.text('42'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('shows filled heart when liked', (tester) async {
      await tester.pumpWidget(
          buildPostCard(postIndex: 0, isLiked: true));
      await tester.pump();

      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('like button is tappable', (tester) async {
      when(() => mockService.likePost(any(), any()))
          .thenAnswer((_) async => 'at://like/new');

      await tester.pumpWidget(buildPostCard(postIndex: 0));
      await tester.pump();

      final likeButton = find.byKey(const Key('like_button_0'));
      expect(likeButton, findsOneWidget);

      await tester.tap(likeButton);
      await tester.pump();
    });

    testWidgets('shows multi-image indicator for multiple images',
        (tester) async {
      await tester.pumpWidget(
          buildPostCard(postIndex: 0, imageCount: 3));
      await tester.pump();

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('does not show indicator for single image', (tester) async {
      await tester.pumpWidget(
          buildPostCard(postIndex: 0, imageCount: 1));
      await tester.pump();

      // The count badge should not appear for single images.
      expect(find.text('1'), findsNothing);
    });
  });
}
