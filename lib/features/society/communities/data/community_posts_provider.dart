import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quest/features/society/communities/data/community_post.dart';

final communityPostsProvider = FutureProvider.autoDispose.family<List<CommunityPost>, String>((ref, communityId) async {
  // Mock implementation for now, replacing Finishd's backend logic
  await Future.delayed(Duration(milliseconds: 500));
  
  return [
    CommunityPost(
      id: 'post_1',
      communityId: communityId,
      authorId: 'user_1',
      authorName: 'Alex',
      content: 'Hey everyone, just joined! Looking forward to learning together.',
      upvotes: 12,
      commentCount: 4,
      createdAt: DateTime.now().subtract(Duration(hours: 2)),
    ),
    CommunityPost(
      id: 'post_2',
      communityId: communityId,
      authorId: 'user_2',
      authorName: 'Sarah',
      content: 'Does anyone have good resources for beginners?',
      upvotes: 8,
      commentCount: 15,
      createdAt: DateTime.now().subtract(Duration(hours: 5)),
    ),
  ];
});
