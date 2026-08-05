import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/quest_button.dart';
import '../../../communities/data/communities_provider.dart';
import '../../../events/data/events_provider.dart';
import '../../../profile/data/user_provider.dart';

class CreateEventSheet extends ConsumerStatefulWidget {
  const CreateEventSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateEventSheet(),
    );
  }

  @override
  ConsumerState<CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends ConsumerState<CreateEventSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();

  String _selectedCategory = 'Technology';
  String? _selectedCommunityId;
  int _xpReward = 150;
  DateTime _eventDate = DateTime.now().add(const Duration(days: 2));
  TimeOfDay _eventTime = const TimeOfDay(hour: 18, minute: 30);

  final List<String> _categories = ['Technology', 'Design', 'Social', 'Gaming', 'Outdoors', 'Business'];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    final location = _locationController.text.trim();

    if (title.isEmpty || desc.isEmpty || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.crimson,
          content: Text('Please fill out all required fields.'),
        ),
      );
      return;
    }

    final newId = '${DateTime.now().millisecondsSinceEpoch}';
    final dateStr = '${_eventDate.month}/${_eventDate.day} @ ${_eventTime.format(context)}';

    final newEvent = Event(
      id: newId,
      title: title,
      description: desc,
      location: location,
      time: dateStr,
      date: '${_eventDate.month}/${_eventDate.day}/${_eventDate.year}',
      category: _selectedCategory,
      communityId: _selectedCommunityId ?? '1',
      xpReward: _xpReward,
      imageUrl: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800',
      attendeesCount: 1,
      isRsvpd: true,
    );

    ref.read(eventsProvider.notifier).addEvent(newEvent);
    ref.read(userProvider.notifier).addXp(100);

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.emerald,
        content: Text('Event "$title" published! (+100 Host XP earned)'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final communitiesStateAsync = ref.watch(communitiesProvider);
    final communitiesState = communitiesStateAsync.value;
    
    if (communitiesState == null) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(color: AppColors.questBlue)),
      );
    }

    if (_selectedCommunityId == null && communitiesState.communities.isNotEmpty) {
      _selectedCommunityId = communitiesState.communities.first.id;
    }

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
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
            const SizedBox(height: 16),

            const Row(
              children: [
                Icon(Icons.event_available, color: AppColors.emerald, size: 24),
                SizedBox(width: 10),
                Text(
                  'Host New Event',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Event Title',
                labelStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _descController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Event Description',
                labelStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _locationController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Location / Venue / Link',
                prefixIcon: const Icon(Icons.location_on, color: AppColors.questBlue),
                labelStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            // Category & Community Pickers
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    dropdownColor: AppColors.card,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Category',
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v ?? 'Technology'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCommunityId,
                    dropdownColor: AppColors.card,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Host Community',
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: communitiesState.communities
                        .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCommunityId = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Date & Time pickers
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.calendar_today, color: AppColors.questBlue, size: 18),
                    label: Text('${_eventDate.month}/${_eventDate.day}/${_eventDate.year}'),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _eventDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setState(() => _eventDate = picked);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.access_time, color: AppColors.questBlue, size: 18),
                    label: Text(_eventTime.format(context)),
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _eventTime,
                      );
                      if (picked != null) setState(() => _eventTime = picked);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // XP Reward Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Attendee XP Reward', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                Text('+$_xpReward XP', style: const TextStyle(color: AppColors.gold, fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            Slider(
              value: _xpReward.toDouble(),
              min: 50,
              max: 500,
              divisions: 9,
              activeColor: AppColors.gold,
              inactiveColor: AppColors.border,
              onChanged: (val) => setState(() => _xpReward = val.toInt()),
            ),
            const SizedBox(height: 20),

            QuestButton(
              label: 'Publish Event (+100 Host XP)',
              variant: QuestButtonVariant.primary,
              isFullWidth: true,
              icon: Icons.rocket_launch,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
