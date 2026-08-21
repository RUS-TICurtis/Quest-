import 'package:flutter/widgets.dart';

import 'package:quest/shared/models/creator_video.dart';

/// Central controller for the TikTok-style creator feed.
///
/// ── Responsibilities ────────────────────────────────────────────────────────
/// 1. Owns the canonical list of [videos] and the [currentIndex].
/// 2. Manages pagination triggers — distinguishes between:
///      • Silent prefetch (user approaching end at normal speed, no loader)
///      • Urgent fetch   (user within 2 items of end, show loader)
/// 3. Implements "Dwell Debouncing" — only activates a page after one frame.
///
/// ── Performance ─────────────────────────────────────────────────────────────
/// Uses [ValueNotifier] to keep the UI "reactive" without calling setState
/// on the entire feed list widget.
///
/// ── Reverse-Scroll Preservation ─────────────────────────────────────────────
/// Videos are ONLY ever appended — never spliced or removed from the front.
/// PageController(keepPage: true) maintains the scroll position. This means
/// upward scrolling always shows the exact historical order with no corruption.
class FeedController {
  final ValueNotifier<List<CreatorVideo>> videos =
      ValueNotifier<List<CreatorVideo>>([]);
  final ValueNotifier<int> currentIndex = ValueNotifier<int>(0);

  /// Emits the index of the video that has "dwelled" (stayed in view for at
  /// least one rendered frame). This is what truly triggers playback and analytics.
  final ValueNotifier<int> activeIndex = ValueNotifier<int>(0);

  bool _disposed = false;

  // Tracks the pending dwell index so rapid swipes only commit the last one.
  int? _pendingDwellIndex;

  bool _isFetchingMore = false;

  /// Called when the user is within [_silentThreshold] items of the end.
  /// The provider fetches silently — no loading indicator is shown.
  final VoidCallback? onSilentPrefetch;

  /// Called when the user is within [_urgentThreshold] items of the end
  /// AND a fetch is still in progress. The screen can choose to show a loader.
  final VoidCallback? onFetchMore;

  /// Number of remaining items that triggers a SILENT background prefetch.
  static const int _silentThreshold = 5;

  /// Number of remaining items that triggers an URGENT fetch with a loader.
  static const int _urgentThreshold = 2;

  FeedController({this.onSilentPrefetch, this.onFetchMore});

  void setVideos(List<CreatorVideo> newVideos) {
    videos.value = List.of(newVideos);
    _isFetchingMore = false;
  }

  void appendVideos(List<CreatorVideo> moreVideos) {
    videos.value = [...videos.value, ...moreVideos];
    _isFetchingMore = false;
  }

  void onPageChanged(int index) {
    if (currentIndex.value == index) return;
    currentIndex.value = index;

    final remaining = videos.value.length - 1 - index;

    // ── Urgent fetch (user is at the very end, show loader if still pending) ──
    if (remaining <= _urgentThreshold && !_isFetchingMore) {
      _isFetchingMore = true;
      onFetchMore?.call();
    }
    // ── Silent prefetch (user approaching end, no loader) ──────────────────
    else if (remaining <= _silentThreshold && !_isFetchingMore) {
      _isFetchingMore = true;
      onSilentPrefetch?.call();
    }

    // ── Dwell Debounce ──────────────────────────────────────────────────────
    // Record the pending index and schedule a post-frame callback. If the user
    // scrolls again before the frame renders, _pendingDwellIndex is overwritten
    // and the stale callback becomes a no-op (the index won't match). This
    // eliminates the UAF bug where a Timer fired after ValueNotifier.dispose().
    _pendingDwellIndex = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;
      if (_pendingDwellIndex != index) return; // User already scrolled further
      activeIndex.value = index;
    });
  }

  /// Called by the feed screen after fetchMore/prefetch completes so the gate
  /// is released and further pagination can trigger.
  void onFetchComplete() {
    _isFetchingMore = false;
  }

  void dispose() {
    _disposed = true;
    videos.dispose();
    currentIndex.dispose();
    activeIndex.dispose();
  }
}
