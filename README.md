# SkyPics

An image-focused Bluesky client built with Flutter. Browse your timeline as a visual grid of photos, switch between feeds, and view images full-screen with pinch-to-zoom.

## Features

- **Masonry image grid** — posts display in a Pinterest-style layout that adapts column count to screen width
- **Feed switching** — toggle between Following and Discover feeds
- **Full-screen viewer** — tap any image to open a swipeable, zoomable gallery with post text accessible via bottom sheet
- **Multi-image support** — collage layouts for posts with 2-4 images, with an overflow indicator for more
- **Likes** — tap to like/unlike posts directly from the grid
- **Infinite scroll** — automatically loads more posts as you scroll down, with image prefetching ahead of the viewport
- **Image caching** — aggressive LRU cache (500 images, 7-day retention) so revisited content loads instantly
- **Secure login** — authenticates via Bluesky App Passwords stored in platform-secure storage, with optional remember-me for auto-login on launch
- **Responsive** — works across mobile, tablet, and desktop with configurable column counts
- **Dark mode** — follows system theme

## Requirements

- Flutter SDK 3.11+
- A Bluesky account with an [App Password](https://bsky.app/settings/app-passwords)

## Getting Started

```
flutter pub get
flutter run
```

## Architecture

- **State management** — Riverpod v3 with `Notifier` / `NotifierProvider`
- **Networking** — [bluesky](https://pub.dev/packages/bluesky) Dart SDK for the AT Protocol
- **Image loading** — `cached_network_image` with a custom `CacheManager` for LRU eviction
- **Secure storage** — `flutter_secure_storage` for credential persistence
