import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/image_post.dart';
import '../providers/feed_provider.dart';
import '../services/image_cache_service.dart';
import '../screens/image_viewer_screen.dart';
import 'multi_image_grid.dart';

/// A single post tile in the masonry grid. Shows images with a like overlay.
class PostCard extends ConsumerWidget {
  final ImagePost post;
  final int postIndex;

  const PostCard({
    super.key,
    required this.post,
    required this.postIndex,
  });

  void _openViewer(BuildContext context, int imageIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImageViewerScreen(
          post: post,
          initialIndex: imageIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area.
          Stack(
            children: [
              _buildImages(context),
              // Like button overlay — lower right.
              Positioned(
                right: 6,
                bottom: 6,
                child: _LikeButton(
                  key: Key('like_button_$postIndex'),
                  isLiked: post.isLiked,
                  likeCount: post.likeCount,
                  onTap: () =>
                      ref.read(feedProvider.notifier).toggleLike(postIndex),
                ),
              ),
              // Multi-image indicator.
              if (post.images.length > 1)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${post.images.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          // Author info.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundImage: post.authorAvatar.isNotEmpty
                      ? CachedNetworkImageProvider(post.authorAvatar,
                          cacheManager: ImageCacheManager.instance)
                      : null,
                  child: post.authorAvatar.isEmpty
                      ? const Icon(Icons.person, size: 14)
                      : null,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    post.authorDisplayName,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImages(BuildContext context) {
    if (post.images.length == 1) {
      return _singleImage(context);
    }
    return _multiImage(context);
  }

  /// Single image — maintains original aspect ratio for the Tetris effect.
  Widget _singleImage(BuildContext context) {
    final img = post.images.first;
    return GestureDetector(
      onTap: () => _openViewer(context, 0),
      child: AspectRatio(
        aspectRatio: img.aspectRatio.clamp(0.5, 2.5),
        child: CachedNetworkImage(
          imageUrl: img.thumb,
          fit: BoxFit.cover,
          cacheManager: ImageCacheManager.instance,
          fadeInDuration: Duration.zero,
          placeholder: (_, __) =>
              Container(color: Colors.grey.shade200),
          errorWidget: (_, __, ___) =>
              const Center(child: Icon(Icons.broken_image)),
        ),
      ),
    );
  }

  /// Multiple images in a collage layout within a fixed bounding box.
  Widget _multiImage(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: MultiImageGrid(
        images: post.images,
        onImageTap: (index) => _openViewer(context, index),
      ),
    );
  }
}

/// Heart-shaped like button with count.
class _LikeButton extends StatelessWidget {
  final bool isLiked;
  final int likeCount;
  final VoidCallback onTap;

  const _LikeButton({
    super.key,
    required this.isLiked,
    required this.likeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black45,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : Colors.white,
                size: 18,
              ),
              if (likeCount > 0) ...[
                const SizedBox(width: 4),
                Text(
                  '$likeCount',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
