import 'package:quest/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quest/features/society/communities/data/communities_repository.dart';

class Community {
  final String id;
  final String name;
  final String description;
  final String category;
  final int memberCount;
  final Color accentColor;
  final IconData icon;
  final List<String> tags;

  Community({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.memberCount = 1,
    this.accentColor = AppColors.questBlue,
    this.icon = Icons.groups,
    this.tags = const ['General', 'Networking'],
  });

  Community copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    int? memberCount,
    Color? accentColor,
    IconData? icon,
    List<String>? tags,
  }) {
    return Community(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      memberCount: memberCount ?? this.memberCount,
      accentColor: accentColor ?? this.accentColor,
      icon: icon ?? this.icon,
      tags: tags ?? this.tags,
    );
  }

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      memberCount: json['memberCount'] as int? ?? 1,
      accentColor: Color(
        json['accentColor'] as int? ?? AppColors.questBlue.toARGB32(),
      ),
      icon: _getCommunityIcon(json['icon'] as int?),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          ['General'],
    );
  }

  static IconData _getCommunityIcon(int? codePoint) {
    if (codePoint == Icons.phone_android.codePoint) return Icons.phone_android;
    if (codePoint == Icons.rocket_launch_outlined.codePoint) {
      return Icons.rocket_launch_outlined;
    }
    if (codePoint == Icons.palette_outlined.codePoint) {
      return Icons.palette_outlined;
    }
    if (codePoint == Icons.directions_run.codePoint) {
      return Icons.directions_run;
    }
    if (codePoint == Icons.psychology_outlined.codePoint) {
      return Icons.psychology_outlined;
    }
    if (codePoint == Icons.photo_camera_outlined.codePoint) {
      return Icons.photo_camera_outlined;
    }
    return Icons.groups;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'memberCount': memberCount,
      'accentColor': accentColor.toARGB32(),
      'icon': icon.codePoint,
      'tags': tags,
    };
  }
}

class CommunitiesState {
  final List<Community> communities;
  final String selectedCategory;
  final String searchQuery;

  CommunitiesState({
    required this.communities,
    this.selectedCategory = 'All',
    this.searchQuery = '',
  });

  List<Community> get filteredCommunities {
    return communities.where((c) {
      final matchesCategory =
          selectedCategory == 'All' || c.category == selectedCategory;
      final matchesSearch =
          searchQuery.isEmpty ||
          c.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          c.description.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  CommunitiesState copyWith({
    List<Community>? communities,
    String? selectedCategory,
    String? searchQuery,
  }) {
    return CommunitiesState(
      communities: communities ?? this.communities,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class CommunitiesNotifier extends AsyncNotifier<CommunitiesState> {
  late final CommunitiesRepository _repository;

  @override
  Future<CommunitiesState> build() async {
    _repository = ref.watch(communitiesRepositoryProvider);
    try {
      final communities = await _repository.getCommunities();
      return CommunitiesState(communities: communities);
    } catch (e) {
      debugPrint('Error fetching communities: $e');
      return CommunitiesState(communities: []);
    }
  }

  void setCategory(String category) {
    if (state.value != null) {
      state = AsyncData(state.value!.copyWith(selectedCategory: category));
    }
  }

  void setSearchQuery(String query) {
    if (state.value != null) {
      state = AsyncData(state.value!.copyWith(searchQuery: query));
    }
  }

  Future<void> addCommunity(Community community) async {
    if (state.value == null) return;

    final newCommunity = await _repository.addCommunity(community);
    state = AsyncData(
      state.value!.copyWith(
        communities: [...state.value!.communities, newCommunity],
      ),
    );
  }

  Community? getCommunityById(String id) {
    try {
      return state.value?.communities.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}

final communitiesProvider =
    AsyncNotifierProvider<CommunitiesNotifier, CommunitiesState>(() {
      return CommunitiesNotifier();
    });
