import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';

class Community {
  final String id;
  final String name;
  final String description;
  final String category;
  final int memberCount;
  final Color accentColor;
  final IconData icon;
  final List<String> tags;

  const Community({
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
}

class CommunitiesState {
  final List<Community> communities;
  final String selectedCategory;
  final String searchQuery;

  const CommunitiesState({
    required this.communities,
    this.selectedCategory = 'All',
    this.searchQuery = '',
  });

  List<Community> get filteredCommunities {
    return communities.where((c) {
      final matchesCategory = selectedCategory == 'All' || c.category == selectedCategory;
      final matchesSearch = searchQuery.isEmpty ||
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

class CommunitiesNotifier extends Notifier<CommunitiesState> {
  @override
  CommunitiesState build() {
    return const CommunitiesState(
      communities: [
        Community(
          id: '1',
          name: 'Flutter Builders',
          description: 'A community for Flutter developers of all skill levels building cross-platform experiences.',
          category: 'Technology',
          memberCount: 2340,
          accentColor: AppColors.questBlue,
          icon: Icons.phone_android,
          tags: ['Mobile', 'Dart', 'Riverpod', 'UI/UX'],
        ),
        Community(
          id: '2',
          name: 'Startup Founders',
          description: 'Connecting early-stage founders, mentors, and investors to build impactful ventures.',
          category: 'Business',
          memberCount: 891,
          accentColor: AppColors.emerald,
          icon: Icons.rocket_launch_outlined,
          tags: ['Venture', 'Pitch', 'Product-Market-Fit'],
        ),
        Community(
          id: '3',
          name: 'Design Systems',
          description: 'Typography, color, motion, design tokens, and component architecture.',
          category: 'Design',
          memberCount: 1204,
          accentColor: AppColors.auroraPurple,
          icon: Icons.palette_outlined,
          tags: ['Tokens', 'Figma', 'Accessibility'],
        ),
        Community(
          id: '4',
          name: 'Local Run Club',
          description: 'Weekly group runs in the city with morning coffee afterwards. All paces welcome.',
          category: 'Fitness',
          memberCount: 543,
          accentColor: AppColors.amber,
          icon: Icons.directions_run,
          tags: ['Running', 'Social', 'Cardio'],
        ),
        Community(
          id: '5',
          name: 'AI & Machine Learning',
          description: 'Deep dives into papers, autonomous agents, generative models, and LLM applications.',
          category: 'Technology',
          memberCount: 5120,
          accentColor: AppColors.skyBlue,
          icon: Icons.psychology_outlined,
          tags: ['LLMs', 'Agents', 'PyTorch', 'Research'],
        ),
        Community(
          id: '6',
          name: 'City Photographers',
          description: 'Share urban photography, street perspectives, and join monthly photo walks.',
          category: 'Arts',
          memberCount: 376,
          accentColor: AppColors.crimson,
          icon: Icons.photo_camera_outlined,
          tags: ['Street', 'Landscape', 'Editing'],
        ),
      ],
    );
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void addCommunity(Community community) {
    state = state.copyWith(communities: [...state.communities, community]);
  }

  Community? getCommunityById(String id) {
    try {
      return state.communities.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}

final communitiesProvider = NotifierProvider<CommunitiesNotifier, CommunitiesState>(() {
  return CommunitiesNotifier();
});
