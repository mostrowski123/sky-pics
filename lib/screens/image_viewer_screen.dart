import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../models/image_post.dart';
import '../services/image_cache_service.dart';

/// Full-screen swipeable image viewer for a single post's images.
class ImageViewerScreen extends StatefulWidget {
  final ImagePost post;
  final int initialIndex;

  const ImageViewerScreen({
    super.key,
    required this.post,
    this.initialIndex = 0,
  });

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late int _currentIndex;
  late PageController _pageController;

  List<PostImage> get _images => widget.post.images;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showPostDetails() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PostDetailsSheet(post: widget.post),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Swipeable photo gallery.
          PhotoViewGallery.builder(
            pageController: _pageController,
            itemCount: _images.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            builder: (context, index) {
              final img = _images[index];
              return PhotoViewGalleryPageOptions(
                imageProvider: CachedNetworkImageProvider(img.fullsize,
                    cacheManager: ImageCacheManager.instance),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
                heroAttributes: PhotoViewHeroAttributes(tag: img.fullsize),
              );
            },
            scrollPhysics: const BouncingScrollPhysics(),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),

          // Close button.
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: IconButton(
              key: const Key('close_viewer'),
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // Post info button — bottom left.
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 16,
            child: IconButton(
              key: const Key('post_info_button'),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
              ),
              icon:
                  const Icon(Icons.info_outline, color: Colors.white, size: 24),
              tooltip: 'Post details',
              onPressed: _showPostDetails,
            ),
          ),

          // Page indicator (only for multi-image posts).
          if (_images.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_images.length, (i) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          i == _currentIndex ? Colors.white : Colors.white38,
                    ),
                  );
                }),
              ),
            ),

          // Alt text overlay.
          if (_images[_currentIndex].alt.isNotEmpty)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 40,
              left: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _images[_currentIndex].alt,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bottom sheet showing post author and text.
class _PostDetailsSheet extends StatelessWidget {
  final ImagePost post;

  const _PostDetailsSheet({required this.post});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.15,
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle.
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Content.
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    // Author row.
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: post.authorAvatar.isNotEmpty
                              ? CachedNetworkImageProvider(post.authorAvatar,
                                  cacheManager: ImageCacheManager.instance)
                              : null,
                          child: post.authorAvatar.isEmpty
                              ? const Icon(Icons.person, size: 18)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.authorDisplayName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '@${post.authorHandle}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (post.text.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        post.text,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    if (post.text.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'No text content.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.grey),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
