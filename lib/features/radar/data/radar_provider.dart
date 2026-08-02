import 'package:flutter_riverpod/flutter_riverpod.dart';

class HubLocation {
  final String id;
  final String name;
  final String address;
  final String category;
  final int activeMembersCount;
  final double distanceMiles;
  final bool isVerified;
  final int xpBonus;
  final String imageUrl;

  const HubLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.category,
    required this.activeMembersCount,
    required this.distanceMiles,
    this.isVerified = true,
    this.xpBonus = 150,
    required this.imageUrl,
  });
}

class RadarMember {
  final String id;
  final String name;
  final String initials;
  final String avatar;
  final String archetype;
  final int distanceFeet;
  final String currentHubId;
  final bool isCheckedIn;
  final String status;
  final double angleRatio; // 0.0 to 1.0 around the radar circle
  final double radiusRatio; // 0.2 to 0.85 from center

  const RadarMember({
    required this.id,
    required this.name,
    required this.initials,
    required this.avatar,
    required this.archetype,
    required this.distanceFeet,
    required this.currentHubId,
    this.isCheckedIn = true,
    required this.status,
    required this.angleRatio,
    required this.radiusRatio,
  });
}

class RadarState {
  final String? selectedHubId;
  final String? checkedInHubId;
  final bool isScanning;
  final List<HubLocation> hubs;
  final List<RadarMember> nearbyMembers;

  const RadarState({
    this.selectedHubId,
    this.checkedInHubId,
    this.isScanning = false,
    required this.hubs,
    required this.nearbyMembers,
  });

  HubLocation? get currentSelectedHub {
    if (selectedHubId == null) return hubs.isNotEmpty ? hubs.first : null;
    return hubs.firstWhere((h) => h.id == selectedHubId, orElse: () => hubs.first);
  }

  bool isUserCheckedIn(String hubId) => checkedInHubId == hubId;

  RadarState copyWith({
    String? selectedHubId,
    String? checkedInHubId,
    bool clearCheckedIn = false,
    bool? isScanning,
    List<HubLocation>? hubs,
    List<RadarMember>? nearbyMembers,
  }) {
    return RadarState(
      selectedHubId: selectedHubId ?? this.selectedHubId,
      checkedInHubId: clearCheckedIn ? null : (checkedInHubId ?? this.checkedInHubId),
      isScanning: isScanning ?? this.isScanning,
      hubs: hubs ?? this.hubs,
      nearbyMembers: nearbyMembers ?? this.nearbyMembers,
    );
  }
}

class RadarNotifier extends Notifier<RadarState> {
  @override
  RadarState build() {
    return const RadarState(
      selectedHubId: 'hub_1',
      checkedInHubId: null,
      isScanning: false,
      hubs: [
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
      ],
      nearbyMembers: [
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
      ],
    );
  }

  void selectHub(String hubId) {
    state = state.copyWith(selectedHubId: hubId);
  }

  void toggleScan() {
    state = state.copyWith(isScanning: !state.isScanning);
  }

  bool checkInToHub(String hubId) {
    if (state.checkedInHubId == hubId) {
      // Checkout
      state = state.copyWith(clearCheckedIn: true);
      return false;
    } else {
      // Checkin
      state = state.copyWith(checkedInHubId: hubId);
      return true;
    }
  }
}

final radarProvider = NotifierProvider<RadarNotifier, RadarState>(() {
  return RadarNotifier();
});
