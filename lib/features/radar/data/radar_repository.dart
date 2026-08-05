import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'radar_provider.dart';

abstract class RadarRepository {
  Future<List<HubLocation>> getHubs();
  Future<List<RadarMember>> getNearbyMembers();
}

class MockRadarRepository implements RadarRepository {
  @override
  Future<List<HubLocation>> getHubs() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      HubLocation(
        id: 'hub_1',
        name: 'The Foundry Commons',
        address: '450 Mission St, San Francisco',
        category: 'Builders Hub',
        activeMembersCount: 14,
        distanceMiles: 0.2,
        xpBonus: 200,
        imageUrl: 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=800',
      ),
      HubLocation(
        id: 'hub_2',
        name: 'Nexus Cyber Lounge',
        address: '88 2nd St, San Francisco',
        category: 'AI & Hackers',
        activeMembersCount: 9,
        distanceMiles: 0.6,
        xpBonus: 150,
        imageUrl: 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=800',
      ),
      HubLocation(
        id: 'hub_3',
        name: 'Pioneer Studio Collective',
        address: '210 Townsend St, San Francisco',
        category: 'Design & Audio',
        activeMembersCount: 6,
        distanceMiles: 1.1,
        xpBonus: 175,
        imageUrl: 'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=800',
      ),
    ];
  }

  @override
  Future<List<RadarMember>> getNearbyMembers() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      RadarMember(
        id: 'mem_1',
        name: 'Jordan Reed',
        initials: 'JR',
        avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
        archetype: 'Builder',
        distanceFeet: 35,
        currentHubId: 'hub_1',
        status: 'Building real-time WebRTC audio pipeline',
        angleRatio: 0.15,
        radiusRatio: 0.35,
      ),
      RadarMember(
        id: 'mem_2',
        name: 'Maya Lin',
        initials: 'ML',
        avatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200',
        archetype: 'Strategist',
        distanceFeet: 60,
        currentHubId: 'hub_1',
        status: 'Reviewing Q3 GTM strategy',
        angleRatio: 0.45,
        radiusRatio: 0.65,
      ),
      RadarMember(
        id: 'mem_3',
        name: 'Samir Patel',
        initials: 'SP',
        avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
        archetype: 'Connector',
        distanceFeet: 85,
        currentHubId: 'hub_1',
        status: 'Organizing weekend hackathon',
        angleRatio: 0.75,
        radiusRatio: 0.50,
      ),
      RadarMember(
        id: 'mem_4',
        name: 'Chloe Bennett',
        initials: 'CB',
        avatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
        archetype: 'Pioneer',
        distanceFeet: 120,
        currentHubId: 'hub_1',
        status: 'Working on generative UI experiments',
        angleRatio: 0.90,
        radiusRatio: 0.80,
      ),
    ];
  }
}

final radarRepositoryProvider = Provider<RadarRepository>((ref) {
  return MockRadarRepository();
});
