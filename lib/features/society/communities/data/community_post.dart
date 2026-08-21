

class CommunityPost {
  final String id;
  final String communityId;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final List<String> mediaUrls;
  final List<String> mediaTypes;
  final List<String> hashtags;
  final bool isSpoiler;
  final bool isHidden;
  final int score;
  final int upvotes;
  final int downvotes;
  final int commentCount;
  final DateTime? createdAt;
  final DateTime? lastActivityAt;
  final bool isLocked;
  final DateTime? pinnedAt;
  final double? trendingScore;
  final int sharesCount;
  final String? mediaType;
  final String? posterPath;
  final bool isFailed;

  CommunityPost({
    required this.id,
    required this.communityId,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.content,
    this.mediaUrls = const [],
    this.mediaTypes = const [],
    this.hashtags = const [],
    this.isSpoiler = false,
    this.isHidden = false,
    this.score = 0,
    this.upvotes = 0,
    this.downvotes = 0,
    this.commentCount = 0,
    this.createdAt,
    this.lastActivityAt,
    this.isLocked = false,
    this.pinnedAt,
    this.trendingScore,
    this.sharesCount = 0,
    this.mediaType,
    this.posterPath,
    this.isFailed = false,
  });
}
