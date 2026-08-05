import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'communities_provider.dart';

abstract class CommunitiesRepository {
  Future<List<Community>> getCommunities();
  Future<Community> addCommunity(Community community);
}

class MockCommunitiesRepository implements CommunitiesRepository {
  final List<Community> _communities = const [
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
  ];

  @override
  Future<List<Community>> getCommunities() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_communities);
  }

  @override
  Future<Community> addCommunity(Community community) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Implementation would add it to Supabase here
    return community;
  }
}

class SupabaseCommunitiesRepository implements CommunitiesRepository {
  final SupabaseClient _client;

  SupabaseCommunitiesRepository(this._client);

  @override
  Future<List<Community>> getCommunities() async {
    final data = await _client.from('communities').select();
    return data.map((json) => Community.fromJson(json)).toList();
  }

  @override
  Future<Community> addCommunity(Community community) async {
    final data = await _client.from('communities').insert(community.toJson()).select().single();
    return Community.fromJson(data);
  }
}

final communitiesRepositoryProvider = Provider<CommunitiesRepository>((ref) {
  // Use real backend instead of mock
  return SupabaseCommunitiesRepository(Supabase.instance.client);
});
