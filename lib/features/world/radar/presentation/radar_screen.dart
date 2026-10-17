import 'package:quest/core/theme/app_colors.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quest/core/theme/quest_icons.dart';
import 'package:quest/features/identity/auth/data/auth_provider.dart';
import 'package:quest/features/identity/profile/data/user_provider.dart';
import 'package:quest/features/world/radar/data/beacon_model.dart';
import 'package:quest/features/world/radar/data/radar_provider.dart';

class RadarScreen extends ConsumerStatefulWidget {
  const RadarScreen({super.key});

  @override
  ConsumerState<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends ConsumerState<RadarScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _sweepController;
  RadarMember? _selectedMember;
  BeaconModel? _selectedBeacon;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radarStateAsync = ref.watch(radarProvider);
    final radarState = radarStateAsync.value;
    final radarNotifier = ref.read(radarProvider.notifier);

    if (radarState == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.questBlue),
        ),
      );
    }

    final currentHub = radarState.currentSelectedHub;
    final isCheckedIn =
        currentHub != null && radarState.isUserCheckedIn(currentHub.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation & Scan Indicator
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/connect');
                      }
                    },
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.emerald,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'LOCAL PARTICIPATION RADAR',
                              style: TextStyle(
                                color: AppColors.emerald,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2),
                        Text(
                          currentHub?.name ?? 'Nearby Hubs',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.radar, color: AppColors.questBlue, size: 16),
                        SizedBox(width: 6),
                        Text(
                          radarState.nearbyMembers.isEmpty
                              ? '0 Active'
                              : '${radarState.nearbyMembers.length} Active',
                          style: TextStyle(
                            color: radarState.nearbyMembers.isEmpty
                                ? AppColors.textMuted
                                : AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Hub Selector Pills
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: radarState.hubs.length,
                separatorBuilder: (context, index) => SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final hub = radarState.hubs[index];
                  final isSelected = hub.id == radarState.selectedHubId;
                  return ChoiceChip(
                    label: Text('${hub.name} (${hub.distanceMiles} mi)'),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        HapticFeedback.selectionClick();
                        radarNotifier.selectHub(hub.id);
                        setState(() {
                          _selectedMember = null;
                          _selectedBeacon = null;
                        });
                      }
                    },
                    selectedColor: AppColors.questBlue.withValues(alpha: 0.25),
                    backgroundColor: AppColors.card,
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.questBlue
                          : AppColors.border,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 12),

            // Main Radar Pulse Canvas & Interactive Overlay
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = min(
                    constraints.maxWidth - 32,
                    constraints.maxHeight - 20,
                  );

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Animated Radar Screen
                      AnimatedBuilder(
                        animation: _sweepController,
                        builder: (context, child) {
                          return CustomPaint(
                            size: Size(size, size),
                            painter: _RadarSweepPainter(
                              sweepAngle: _sweepController.value * 2 * pi,
                            ),
                          );
                        },
                      ),

                      // User Center Point
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.questBlue,
                          border: Border.all(
                            color: AppColors.textPrimary,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.questBlue.withValues(alpha: 0.6),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.person,
                          color: AppColors.textPrimary,
                          size: 16,
                        ),
                      ),

                      // Member Blips on Radar
                      ...radarState.nearbyMembers.map((member) {
                        final angle = member.angleRatio * 2 * pi;
                        final radius = (size / 2) * member.radiusRatio;
                        final x = (size / 2) + (radius * cos(angle)) - 18;
                        final y = (size / 2) + (radius * sin(angle)) - 18;
                        final isSelected = _selectedMember?.id == member.id;

                        return Positioned(
                          left: (constraints.maxWidth - size) / 2 + x,
                          top: (constraints.maxHeight - size) / 2 + y,
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectedMember = isSelected ? null : member;
                              });
                            },
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 200),
                              width: isSelected ? 42 : 34,
                              height: isSelected ? 42 : 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.gold
                                      : AppColors.emerald,
                                  width: isSelected ? 2.5 : 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (isSelected
                                                ? AppColors.gold
                                                : AppColors.emerald)
                                            .withValues(alpha: 0.5),
                                    blurRadius: 8,
                                  ),
                                ],
                                image: DecorationImage(
                                  image: NetworkImage(member.avatar),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      // Active Beacon Pins on Radar
                      ...radarState.activeBeacons.map((beacon) {
                        final angle = beacon.angleRatio * 2 * pi;
                        final radius = (size / 2) * beacon.radiusRatio;
                        final x = (size / 2) + (radius * cos(angle)) - 20;
                        final y = (size / 2) + (radius * sin(angle)) - 20;
                        final isSelected = _selectedBeacon?.id == beacon.id;

                        return Positioned(
                          left: (constraints.maxWidth - size) / 2 + x,
                          top: (constraints.maxHeight - size) / 2 + y,
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectedBeacon = isSelected ? null : beacon;
                                _selectedMember = null;
                              });
                            },
                            child: AnimatedBuilder(
                              animation: _sweepController,
                              builder: (context, child) {
                                final pulse = sin(
                                  (_sweepController.value * 2 * pi) +
                                      (beacon.angleRatio * 4),
                                ).abs();
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Radiating beacon pulse ring
                                    Container(
                                      width: 44 + (pulse * 14),
                                      height: 44 + (pulse * 14),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.coral.withValues(
                                            alpha: 0.8 - (pulse * 0.5),
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    // Core beacon marker
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: isSelected ? 42 : 36,
                                      height: isSelected ? 42 : 36,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            AppColors.coral,
                                            Color(0xFFFF8A00),
                                          ],
                                        ),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.gold
                                              : Colors.white,
                                          width: isSelected ? 2.5 : 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.coral.withValues(
                                              alpha: 0.6,
                                            ),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.podcasts_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        );
                      }),
                      if (radarState.nearbyMembers.isEmpty &&
                          radarState.activeBeacons.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.radar_rounded,
                                  size: 40,
                                  color: AppColors.textMuted.withValues(alpha: 0.6),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'No builders active on radar right now',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            // Bottom Selected Beacon Card, Member Card, or Check-In Action
            if (_selectedBeacon != null)
              _buildSelectedBeaconCard(_selectedBeacon!, radarNotifier)
            else if (_selectedMember != null)
              _buildSelectedMemberCard(_selectedMember!)
            else if (currentHub != null)
              _buildCheckInBar(currentHub, isCheckedIn, radarNotifier),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.coral,
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.podcasts_rounded, size: 20),
        label: const Text(
          'Drop Beacon',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.3),
        ),
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showDropBeaconSheet(context, radarNotifier, currentHub);
        },
      ),
    );
  }

  Widget _buildSelectedBeaconCard(
    BeaconModel beacon,
    RadarNotifier notifier,
  ) {
    final currentUserId = ref.read(authProvider).user?.id ?? '';
    final isJoined = beacon.isUserJoined(currentUserId);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.coral.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.coral.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.coral.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.podcasts_rounded,
                  color: AppColors.coral,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            beacon.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.coral.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.coral.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                color: AppColors.coral,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                beacon.timeRemainingFormatted,
                                style: const TextStyle(
                                  color: AppColors.coral,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hosted by ${beacon.creatorName} • ${beacon.hubName}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close,
                  color: AppColors.textPrimary54,
                  size: 20,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _selectedBeacon = null;
                  });
                },
              ),
            ],
          ),
          if (beacon.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              beacon.description,
              style: const TextStyle(
                color: AppColors.textPrimary80,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              // Attendee avatars stack
              if (beacon.attendeeAvatars.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  height: 28,
                  width: (beacon.attendeeAvatars.length * 18.0) + 14,
                  child: Stack(
                    children: List.generate(
                      beacon.attendeeAvatars.length,
                      (i) => Positioned(
                        left: i * 18.0,
                        child: CircleAvatar(
                          radius: 13,
                          backgroundColor: AppColors.surface,
                          child: CircleAvatar(
                            radius: 12,
                            backgroundImage:
                                NetworkImage(beacon.attendeeAvatars[i]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Text(
                '${beacon.attendeeCount} ${beacon.attendeeCount == 1 ? 'person' : 'people'} joined',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isJoined ? AppColors.emerald : AppColors.coral,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onPressed: isJoined
                    ? null
                    : () async {
                        final authState = ref.read(authProvider);
                        if (authState.accessLevel != AccessLevel.member) {
                          _promptSignIn('join meetups');
                          return;
                        }
                        HapticFeedback.heavyImpact();
                        final success = await notifier.joinBeacon(beacon.id);
                        if (success && mounted) {
                          setState(() {
                            _selectedBeacon = _selectedBeacon?.copyWith(
                              attendeeIds: [
                                ...beacon.attendeeIds,
                                currentUserId,
                              ],
                            );
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '🎉 Joined Beacon! +25 XP awarded.',
                              ),
                              backgroundColor: AppColors.emerald,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                icon: Icon(
                  isJoined
                      ? Icons.check_circle_outline
                      : Icons.add_location_alt_outlined,
                  size: 16,
                ),
                label: Text(
                  isJoined ? 'Joined' : 'Join (+25 XP)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _promptSignIn(String action) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Member Access Required',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Please sign in with a full account to $action and earn participation XP.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.questBlue,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/login');
            },
            child: const Text('Sign In', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDropBeaconSheet(
    BuildContext context,
    RadarNotifier notifier,
    HubLocation? currentHub,
  ) {
    final authState = ref.read(authProvider);
    if (authState.accessLevel != AccessLevel.member) {
      _promptSignIn('drop beacons');
      return;
    }

    final titleController = TextEditingController();
    final descController = TextEditingController();
    int selectedDurationMinutes = 120;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border(
                    top: BorderSide(color: AppColors.coral, width: 2),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.coral.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.podcasts_rounded,
                            color: AppColors.coral,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ignite a Radar Beacon',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Broadcast a spontaneous meetup at ${currentHub?.name ?? 'current hub'}',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: titleController,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Meetup Title',
                        labelStyle: const TextStyle(color: AppColors.textMuted),
                        hintText: 'e.g. Coffee & Fellowship, Evening Prayer Walk',
                        hintStyle: TextStyle(
                          color: AppColors.textMuted.withValues(alpha: 0.6),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.coral,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Details / Where to find you',
                        labelStyle: const TextStyle(color: AppColors.textMuted),
                        hintText: 'e.g. Sitting near the corner table with Bible open…',
                        hintStyle: TextStyle(
                          color: AppColors.textMuted.withValues(alpha: 0.6),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.coral,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Beacon Duration',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [30, 60, 120, 240].map((mins) {
                        final isSel = selectedDurationMinutes == mins;
                        final label = mins < 60 ? '${mins}m' : '${mins ~/ 60}h';
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(label),
                            selected: isSel,
                            selectedColor:
                                AppColors.coral.withValues(alpha: 0.25),
                            backgroundColor: AppColors.surface,
                            side: BorderSide(
                              color: isSel ? AppColors.coral : AppColors.border,
                            ),
                            labelStyle: TextStyle(
                              color: isSel
                                  ? AppColors.coral
                                  : AppColors.textMuted,
                              fontWeight: isSel
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 12,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                HapticFeedback.selectionClick();
                                setSheetState(() {
                                  selectedDurationMinutes = mins;
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.coral,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        icon: const Icon(Icons.bolt, size: 20),
                        label: const Text(
                          'Ignite Beacon (+50 XP)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () async {
                          final title = titleController.text.trim();
                          if (title.isEmpty) {
                            ScaffoldMessenger.of(sheetCtx).showSnackBar(
                              const SnackBar(
                                content: Text('Please provide a meetup title.'),
                                backgroundColor: AppColors.crimson,
                              ),
                            );
                            return;
                          }
                          HapticFeedback.heavyImpact();
                          Navigator.pop(sheetCtx);

                          final messenger = ScaffoldMessenger.of(context);
                          final success = await notifier.dropBeacon(
                            title: title,
                            description: descController.text.trim(),
                            hubId: currentHub?.id ?? 'hub_1',
                            durationMinutes: selectedDurationMinutes,
                          );

                          if (success && mounted) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '🔥 Beacon Ignited on Radar! +50 XP awarded.',
                                ),
                                backgroundColor: AppColors.emerald,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSelectedMemberCard(RadarMember member) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.background.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(member.avatar),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          member.name,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                QuestIcons.forArchetype(member.archetype),
                                size: 11,
                                color: AppColors.gold,
                              ),
                              SizedBox(width: 4),
                              Text(
                                member.archetype,
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      '${member.distanceFeet} ft away • Checked in',
                      style: TextStyle(
                        color: AppColors.emerald,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: AppColors.textPrimary54,
                  size: 20,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _selectedMember = null;
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.all(10),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '“${member.status}”',
              style: TextStyle(
                color: AppColors.textPrimary70,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.questBlue,
                    foregroundColor: AppColors.textPrimary,
                    padding: EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: Icon(Icons.chat_bubble_outline, size: 16),
                  label: Text(
                    'Direct Chat',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.push('/messages/t1');
                  },
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(color: AppColors.border),
                    padding: EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: Icon(Icons.person_outline, size: 16),
                  label: Text('View Matrix', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.push('/profile/${member.id}');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInBar(
    HubLocation hub,
    bool isCheckedIn,
    RadarNotifier notifier,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hub.address,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.bolt, color: AppColors.gold, size: 14),
                      SizedBox(width: 4),
                      Text(
                        '+${hub.xpBonus} XP Verified Check-in Bonus',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${hub.activeMembersCount} here now',
                  style: TextStyle(
                    color: AppColors.textPrimary70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isCheckedIn
                    ? AppColors.crimson.withValues(alpha: 0.2)
                    : AppColors.emerald,
                foregroundColor: isCheckedIn
                    ? AppColors.crimson
                    : AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: isCheckedIn
                      ? BorderSide(color: AppColors.crimson)
                      : BorderSide.none,
                ),
              ),
              icon: Icon(isCheckedIn ? Icons.logout : Icons.verified, size: 20),
              label: Text(
                isCheckedIn
                    ? 'Leave & Check Out'
                    : 'Check In To Physical Venue',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                if (isCheckedIn) {
                  HapticFeedback.mediumImpact();
                  notifier.checkInToHub(hub.id);
                } else {
                  HapticFeedback.heavyImpact();
                  final didCheckIn = notifier.checkInToHub(hub.id);
                  if (didCheckIn) {
                    ref.read(userProvider.notifier).addXp(hub.xpBonus);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.card,
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: AppColors.emerald),
                            SizedBox(width: 10),
                            Text(
                              'Checked in at ${hub.name}! +${hub.xpBonus} XP gained.',
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarSweepPainter extends CustomPainter {
  final double sweepAngle;

  _RadarSweepPainter({required this.sweepAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle fill with subtle radial gradient
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [AppColors.card, AppColors.surface.withValues(alpha: 0.95)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Outer glow ring
    final outerRingPaint = Paint()
      ..color = AppColors.emerald.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, outerRingPaint);

    // Concentric grid circles
    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, radius * 0.33, gridPaint);
    canvas.drawCircle(center, radius * 0.66, gridPaint);

    // Crosshairs
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      gridPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      gridPaint,
    );

    // Sweep Gradient Cone
    final sweepRect = Rect.fromCircle(center: center, radius: radius);
    final sweepGradient = SweepGradient(
      startAngle: 0.0,
      endAngle: pi / 2,
      colors: [
        AppColors.emerald.withValues(alpha: 0.4),
        AppColors.emerald.withValues(alpha: 0.0),
      ],
      transform: GradientRotation(sweepAngle - (pi / 2)),
    );

    final sweepPaint = Paint()
      ..shader = sweepGradient.createShader(sweepRect)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, sweepPaint);

    // Leading sweep beam line
    final beamEnd = Offset(
      center.dx + (radius * cos(sweepAngle)),
      center.dy + (radius * sin(sweepAngle)),
    );
    final beamPaint = Paint()
      ..color = AppColors.emerald
      ..strokeWidth = 2.0;
    canvas.drawLine(center, beamEnd, beamPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarSweepPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle;
  }
}
