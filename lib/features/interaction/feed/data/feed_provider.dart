import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quest/features/interaction/feed/data/feed_repository.dart';
import 'package:quest/features/interaction/feed/presentation/controller/feed_controller.dart';
import 'package:quest/shared/models/creator_video.dart';

final feedControllerProvider = Provider.autoDispose<FeedController>((ref) {
  final repository = ref.watch(feedRepositoryProvider);

  Map<String, dynamic>? nextCursor;
  bool isFetching = false;
  bool hasMore = true;

  late final FeedController controller;

  // Shared fetch logic — used by both callbacks.
  Future<void> doFetch({bool silent = false}) async {
    if (isFetching || !hasMore) return;
    isFetching = true;
    try {
      final result = await repository.getFeed(cursor: nextCursor);
      if (result.videos.isEmpty) {
        hasMore = false;
        controller.onFetchComplete();
      } else {
        nextCursor = result.nextCursor;
        controller.appendVideos(result.videos);
        // appendVideos already calls onFetchComplete internally via
        // setting _isFetchingMore = false and isLoadingMore = false.
      }
    } catch (_) {
      controller.onFetchComplete();
    } finally {
      isFetching = false;
    }
  }

  controller = FeedController(
    // Urgent: user within 2 items of end — spinner already shown via isLoadingMore.
    onFetchMore: () => doFetch(silent: false),
    // Silent: user within 5 items of end — no spinner, prefetch in background.
    onSilentPrefetch: () => doFetch(silent: true),
  );

  // Register dispose callback so ValueNotifiers are released when the
  // feedControllerProvider is auto-disposed (e.g., when FeedScreen exits).
  ref.onDispose(controller.dispose);

  // Initial fetch
  Future.microtask(() async {
    isFetching = true;
    try {
      final result = await repository.getFeed();
      if (result.videos.isEmpty) {
        hasMore = false;
      } else {
        nextCursor = result.nextCursor;
        controller.setVideos(result.videos);
      }
    } finally {
      isFetching = false;
      controller.onFetchComplete();
    }
  });

  return controller;
});

final feedStateProvider = FutureProvider.autoDispose<List<CreatorVideo>>((ref) async {
  final repository = ref.watch(feedRepositoryProvider);
  final result = await repository.getFeed();
  return result.videos;
});
