_Last Modified: 2026-08-06_

# 4. Design System

Quest❕ uses a centralized design system built entirely with Dart constants — no external theming packages.

## Color Palette (`lib/core/theme/app_colors.dart`)

| Token | Value | Usage |
|---|---|---|
| `AppColors.background` | `#0A0A0F` | Scaffold backgrounds |
| `AppColors.surface` | `#12121A` | Card/modal backgrounds |
| `AppColors.card` | `#1A1A2E` | Elevated card surfaces |
| `AppColors.border` | `#2A2A3E` | Dividers, input borders |
| `AppColors.questBlue` | `#4F8EF7` | Primary accent, CTAs, glow |
| `AppColors.auroraPurple` | `#9B59F5` | Secondary accent, gradients |
| `AppColors.emerald` | `#2ECC71` | Success, active states |
| `AppColors.gold` | `#F1C40F` | XP, achievements, badges |
| `AppColors.crimson` | `#E74C3C` | Danger, destructive actions |
| `AppColors.skyBlue` | `#5DADE2` | Links, secondary interactive |
| `AppColors.textPrimary` | `#FFFFFF` | Primary body text |
| `AppColors.textSecondary` | `#B0B3C1` | Subtitles, meta text |
| `AppColors.textMuted` | `#6B6E82` | Captions, disabled states |

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
