import 'package:flutter/material.dart';

/// Semantic Quest iconography mapping for archetypes, ranks, quests, and events.
class QuestIcons {
  QuestIcons._();

  // Archetype Glyphs
  static const IconData builder = Icons.precision_manufacturing_outlined;
  static const IconData explorer = Icons.explore_outlined;
  static const IconData connector = Icons.diversity_3_outlined;
  static const IconData strategist = Icons.insights_outlined;
  static const IconData scholar = Icons.auto_stories_outlined;
  static const IconData pioneer = Icons.flag_outlined;

  // Gamification & Progression Glyphs
  static const IconData streak = Icons.local_fire_department_rounded;
  static const IconData xpBadge = Icons.workspace_premium_rounded;
  static const IconData levelUp = Icons.upgrade_rounded;
  static const IconData dailyQuest = Icons.task_alt_rounded;
  static const IconData legendaryQuest = Icons.military_tech_rounded;
  static const IconData guild = Icons.shield_moon_outlined;

  // Interaction & Multimedia Glyphs
  static const IconData voiceNote = Icons.mic_rounded;
  static const IconData waveform = Icons.graphic_eq_rounded;
  static const IconData aiGuide = Icons.auto_awesome_rounded;
  static const IconData rsvp = Icons.how_to_reg_rounded;
  static const IconData storyRing = Icons.motion_photos_on_outlined;

  // Archetype icon resolver
  static IconData forArchetype(String archetypeName) {
    switch (archetypeName.toLowerCase()) {
      case 'builder':
      case 'developer':
      case 'engineer':
        return builder;
      case 'explorer':
      case 'adventurer':
        return explorer;
      case 'connector':
      case 'community':
      case 'networker':
        return connector;
      case 'strategist':
      case 'founder':
      case 'leader':
        return strategist;
      case 'scholar':
      case 'researcher':
        return scholar;
      case 'pioneer':
      case 'creator':
        return pioneer;
      default:
        return Icons.person_outline;
    }
  }
}
