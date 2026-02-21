/// A simplified model representing a Bluesky post that contains images.
class ImagePost {
  final String uri;
  final String cid;
  final String authorHandle;
  final String authorDisplayName;
  final String authorAvatar;
  final String text;
  final List<PostImage> images;
  final int likeCount;
  final bool isLiked;

  /// The AT URI of the viewer's like record, if liked. Needed for un-liking.
  final String? viewerLikeUri;

  const ImagePost({
    required this.uri,
    required this.cid,
    required this.authorHandle,
    required this.authorDisplayName,
    required this.authorAvatar,
    required this.text,
    required this.images,
    this.likeCount = 0,
    this.isLiked = false,
    this.viewerLikeUri,
  });

  ImagePost copyWith({
    bool? isLiked,
    int? likeCount,
    String? viewerLikeUri,
  }) {
    return ImagePost(
      uri: uri,
      cid: cid,
      authorHandle: authorHandle,
      authorDisplayName: authorDisplayName,
      authorAvatar: authorAvatar,
      text: text,
      images: images,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
      viewerLikeUri: viewerLikeUri ?? this.viewerLikeUri,
    );
  }
}

class PostImage {
  final String thumb;
  final String fullsize;
  final String alt;
  final double aspectRatio;

  const PostImage({
    required this.thumb,
    required this.fullsize,
    required this.alt,
    required this.aspectRatio,
  });
}
