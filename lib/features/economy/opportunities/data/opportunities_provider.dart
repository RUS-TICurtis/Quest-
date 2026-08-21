import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'opportunity_models.dart';

final opportunitiesProvider = Provider<OpportunitiesRepository>((ref) {
  return OpportunitiesRepository();
});

class OpportunitiesRepository {
  List<Opportunity> getMockOpportunities() {
    return [
      Opportunity(
        id: 'o1',
        providerId: 'org1',
        title: 'Junior Flutter Developer',
        description:
            'Join our startup to build the next generation of social tech.',
        type: OpportunityType.job,
        location: 'Remote',
        isPaid: true,
        compensationAmount: 85000.0,
        createdAt: DateTime.now().subtract(Duration(days: 3)),
        expiresAt: DateTime.now().add(Duration(days: 30)),
      ),
      Opportunity(
        id: 'o2',
        providerId: 'community_ai',
        title: 'Machine Learning Research Assistant',
        description: 'Help us train our recommendation models.',
        type: OpportunityType.research,
        location: 'University Campus',
        isPaid: true,
        compensationAmount: 25.0, // per hour
        createdAt: DateTime.now().subtract(Duration(days: 1)),
        expiresAt: DateTime.now().add(Duration(days: 14)),
      ),
      Opportunity(
        id: 'o3',
        providerId: 'org2',
        title: 'Beach Cleanup Volunteer',
        description: 'Join us this Saturday for a community cleanup event.',
        type: OpportunityType.volunteer,
        location: 'Santa Monica Beach',
        isPaid: false,
        createdAt: DateTime.now().subtract(Duration(hours: 12)),
        expiresAt: DateTime.now().add(Duration(days: 4)),
      ),
    ];
  }
}
