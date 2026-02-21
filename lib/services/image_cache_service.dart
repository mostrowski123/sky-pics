import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Custom cache manager for Bluesky images with larger capacity and LRU eviction.
///
/// - 1000 max cached objects (vs default 200)
/// - 7-day stale period (vs default 30 days) — keeps cache fresh
/// - flutter_cache_manager handles LRU eviction automatically when the max is hit
class ImageCacheManager {
  static const _key = 'skyPicsImageCache';

  static final instance = CacheManager(
    Config(
      _key,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 1000,
    ),
  );
}
