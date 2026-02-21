import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/image_post.dart';
import '../services/image_cache_service.dart';

/// A grid layout for 2-4 images in a post, displayed in a square bounding box.
/// Handles 2, 3, and 4+ image layouts similar to Twitter/Bluesky multi-image.
class MultiImageGrid extends StatelessWidget {
  final List<PostImage> images;
  final void Function(int index) onImageTap;

  const MultiImageGrid({
    super.key,
    required this.images,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return switch (images.length) {
      2 => _twoImages(),
      3 => _threeImages(),
      _ => _fourImages(),
    };
  }

  /// Two images side by side.
  Widget _twoImages() {
    return Row(
      children: [
        Expanded(child: _tile(0)),
        const SizedBox(width: 2),
        Expanded(child: _tile(1)),
      ],
    );
  }

  /// One large left, two stacked right.
  Widget _threeImages() {
    return Row(
      children: [
        Expanded(child: _tile(0)),
        const SizedBox(width: 2),
        Expanded(
          child: Column(
            children: [
              Expanded(child: _tile(1)),
              const SizedBox(height: 2),
              Expanded(child: _tile(2)),
            ],
          ),
        ),
      ],
    );
  }

  /// 2x2 grid.
  Widget _fourImages() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _tile(0)),
              const SizedBox(width: 2),
              Expanded(child: _tile(1)),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _tile(2)),
              const SizedBox(width: 2),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _tile(3),
                    if (images.length > 4)
                      Container(
                        color: Colors.black45,
                        alignment: Alignment.center,
                        child: Text(
                          '+${images.length - 4}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tile(int index) {
    if (index >= images.length) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => onImageTap(index),
      child: CachedNetworkImage(
        imageUrl: images[index].thumb,
        fit: BoxFit.cover,
        cacheManager: ImageCacheManager.instance,
        fadeInDuration: Duration.zero,
        width: double.infinity,
        height: double.infinity,
        placeholder: (_, __) => Container(color: Colors.grey.shade200),
        errorWidget: (_, __, ___) =>
            const Center(child: Icon(Icons.broken_image)),
      ),
    );
  }
}
