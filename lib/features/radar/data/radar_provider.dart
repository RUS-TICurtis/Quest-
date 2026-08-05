import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'radar_repository.dart';

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

  factory HubLocation.fromJson(Map<String, dynamic> json) {
    return HubLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      category: json['category'] as String,
      activeMembersCount: json['activeMembersCount'] as int? ?? 0,
      distanceMiles: (json['distanceMiles'] as num?)?.toDouble() ?? 0.0,
      isVerified: json['isVerified'] as bool? ?? true,
      xpBonus: json['xpBonus'] as int? ?? 150,
      imageUrl: json['imageUrl'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'category': category,
      'activeMembersCount': activeMembersCount,
      'distanceMiles': distanceMiles,
      'isVerified': isVerified,
      'xpBonus': xpBonus,
      'imageUrl': imageUrl,
    };
  }
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

  factory RadarMember.fromJson(Map<String, dynamic> json) {
    return RadarMember(
      id: json['id'] as String,
      name: json['name'] as String,
      initials: json['initials'] as String,
      avatar: json['avatar'] as String,
      archetype: json['archetype'] as String,
      distanceFeet: json['distanceFeet'] as int? ?? 0,
      currentHubId: json['currentHubId'] as String,
      isCheckedIn: json['isCheckedIn'] as bool? ?? true,
      status: json['status'] as String,
      angleRatio: (json['angleRatio'] as num?)?.toDouble() ?? 0.0,
      radiusRatio: (json['radiusRatio'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'initials': initials,
      'avatar': avatar,
      'archetype': archetype,
      'distanceFeet': distanceFeet,
      'currentHubId': currentHubId,
      'isCheckedIn': isCheckedIn,
      'status': status,
      'angleRatio': angleRatio,
      'radiusRatio': radiusRatio,
    };
  }
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

class RadarNotifier extends AsyncNotifier<RadarState> {
  late final RadarRepository _repository;

  @override
  Future<RadarState> build() async {
    _repository = ref.watch(radarRepositoryProvider);
    final hubs = await _repository.getHubs();
    final members = await _repository.getNearbyMembers();
    
    return RadarState(
      selectedHubId: hubs.isNotEmpty ? hubs.first.id : null,
      checkedInHubId: null,
      isScanning: false,
      hubs: hubs,
      nearbyMembers: members,
    );
  }

  void selectHub(String hubId) {
    if (state.value != null) {
      state = AsyncData(state.value!.copyWith(selectedHubId: hubId));
    }
  }

  void toggleScan() {
    if (state.value != null) {
      state = AsyncData(state.value!.copyWith(isScanning: !state.value!.isScanning));
    }
  }

  bool checkInToHub(String hubId) {
    if (state.value == null) return false;
    
    if (state.value!.checkedInHubId == hubId) {
      // Checkout
      state = AsyncData(state.value!.copyWith(clearCheckedIn: true));
      return false;
    } else {
      // Checkin
      state = AsyncData(state.value!.copyWith(checkedInHubId: hubId));
      return true;
    }
  }
}

final radarProvider = AsyncNotifierProvider<RadarNotifier, RadarState>(() {
  return RadarNotifier();
});
