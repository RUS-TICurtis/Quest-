_Last Modified: 2026-10-17_

# 4. Design System

Quest uses a centralized design system built entirely with Dart constants — no external theming packages.

## Color Palette (`lib/core/theme/app_colors.dart`)

| Token | Value | Usage |
|---|---|---|
| `AppColors.background` | `#030712` | Scaffold backgrounds |
| `AppColors.surface` | `#111827` | Card/modal backgrounds |
| `AppColors.card` | `#1F2937` | Elevated card surfaces |
| `AppColors.border` | `#374151` | Dividers, input borders |
| `AppColors.questBlue` | `#2563EB` | Primary accent, CTAs, glow |
| `AppColors.auroraPurple` | `#7C3AED` | Secondary accent, gradients |
| `AppColors.emerald` | `#10B981` | Success, active states |
| `AppColors.gold` | `#FBBF24` | XP, achievements, badges |
| `AppColors.amber` | `#F59E0B` | Warning, pending status |
| `AppColors.crimson` | `#EF4444` | Danger, destructive actions |
| `AppColors.coral` | `#FF5722` | Spontaneous beacons, kinetic pulse |
| `AppColors.skyBlue` | `#38BDF8` | Links, secondary interactive |
| `AppColors.textPrimary` | `#FFFFFF` | Primary body text |
| `AppColors.textPrimary87` | `0xDEFFFFFF` | High-emphasis body text |
| `AppColors.textPrimary80` | `0xCCFFFFFF` | Secondary content text |
| `AppColors.textPrimary70` | `0xB3FFFFFF` | Subtitles, secondary text |
| `AppColors.textSecondary` | `#9CA3AF` | Supporting descriptions |
| `AppColors.textMuted` | `#6B7280` | Captions, disabled states |

## Theme Definition (`lib/core/theme/app_theme.dart`)

- `AppTheme.dark` — the single theme used across all platforms
- Defines `MaterialTheme.colorScheme` from seeds, overrides `AppBarTheme`, `CardTheme`, `InputDecorationTheme`, `ElevatedButtonTheme`, `BottomNavigationBarTheme`, `NavigationRailTheme`
- All text styles use the `Outfit` Google Font family

## Icon System (`lib/core/theme/quest_icons.dart`)

`QuestIcons` is a sealed class with semantic icon constants for:
- Archetypes (Builder, Explorer, Connector, Strategist, Scholar, Pioneer)
- Gamification (streak, xpBadge, levelUp, dailyQuest, guild)
- Interaction (voiceNote, waveform, aiGuide, rsvp, storyRing)
- Archetype resolver: `QuestIcons.forArchetype(String name)` returns the correct icon

## Shared Widgets (`lib/shared/widgets/`)

| Widget | Description |
|---|---|
| `QuestButton` | Primary button with press-scale animation; supports `primary`, `secondary`, `xp`, `ghost` variants |

## Design Rules
1. Never hard-code colors — always use `AppColors.*` tokens
2. Never use Material default themes — always inherit from `AppTheme.dark`
3. Ambient glow effects use `BoxShadow` with `.withValues(alpha: 0.4)` on `questBlue` or `auroraPurple`
4. All interactive elements should use `HapticFeedback.lightImpact()` on tap
5. Spring animation curves: prefer `Curves.easeOutBack` for scale, `Curves.easeInOut` for opacity
