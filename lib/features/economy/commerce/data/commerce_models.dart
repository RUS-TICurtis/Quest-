enum ListingType { product, service, classified }

enum ListingCondition {
  newItem,
  usedLikeNew,
  usedGood,
  usedFair,
  notApplicable,
}

class Listing {
  final String id;
  final String sellerId;
  final String title;
  final String description;
  final double
  price; // Can be in fiat or Quest Coins (handled by currency type later)
  final String currency; // 'USD', 'QUEST'
  final ListingType type;
  final ListingCondition condition;
  final List<String> imageUrls;
  final DateTime createdAt;

  Listing({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.price,
    this.currency = 'USD',
    required this.type,
    this.condition = ListingCondition.notApplicable,
    this.imageUrls = const [],
    required this.createdAt,
  });
}
