import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'commerce_models.dart';

final commerceProvider = Provider<CommerceRepository>((ref) {
  return CommerceRepository();
});

class CommerceRepository {
  List<Listing> getMockListings() {
    return [
      Listing(
        id: 'c1',
        sellerId: 'user1',
        title: 'Sony A7III Camera Body',
        description: 'Used for a year, in great condition. Switching to video.',
        price: 1200.0,
        currency: 'USD',
        type: ListingType.classified,
        condition: ListingCondition.usedGood,
        createdAt: DateTime.now().subtract(Duration(days: 2)),
      ),
      Listing(
        id: 'c2',
        sellerId: 'user2',
        title: 'Graphic Design Services',
        description:
            'I will design a modern logo for your startup or community.',
        price: 50.0,
        currency: 'QUEST',
        type: ListingType.service,
        createdAt: DateTime.now().subtract(Duration(hours: 5)),
      ),
      Listing(
        id: 'c3',
        sellerId: 'org1',
        title: 'Quest Official Hoodie',
        description: 'Premium embroidered hoodie.',
        price: 45.0,
        currency: 'USD',
        type: ListingType.product,
        condition: ListingCondition.newItem,
        createdAt: DateTime.now().subtract(Duration(days: 10)),
      ),
    ];
  }
}
