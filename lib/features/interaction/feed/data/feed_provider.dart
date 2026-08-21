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

  controller = FeedController(
    onFetchMore: () async {
      if (isFetching || !hasMore) return;
      isFetching = true;
      try {
        final result = await repository.getFeed(cursor: nextCursor);
        if (result.videos.isEmpty) {
          hasMore = false;
        } else {
          nextCursor = result.nextCursor;
          controller.appendVideos(result.videos);
        }
      } finally {
        isFetching = false;
        controller.onFetchComplete();
      }
    },
    onSilentPrefetch: () async {
      if (isFetching || !hasMore) return;
      isFetching = true;
      try {
        final result = await repository.getFeed(cursor: nextCursor);
        if (result.videos.isEmpty) {
          hasMore = false;
        } else {
          nextCursor = result.nextCursor;
          controller.appendVideos(result.videos);
        }
      } finally {
        isFetching = false;
        controller.onFetchComplete();
      }
    }
  );

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
