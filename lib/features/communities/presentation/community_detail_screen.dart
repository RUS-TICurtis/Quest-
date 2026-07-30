import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'communities_screen.dart';

class CommunityDetailScreen extends StatefulWidget {
  final CommunityModel community;
  const CommunityDetailScreen({super.key, required this.community});

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  bool _isJoined = false;

  @override
  void initState() {
    super.initState();
    _isJoined = widget.community.isJoined;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.community;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      c.accentColor.withValues(alpha: 0.3),
                      AppColors.surface,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 48),
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: c.accentColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: c.accentColor.withValues(alpha: 0.5)),
                        ),
                        child: Icon(c.icon, color: c.accentColor, size: 38),
                      ),
                      const SizedBox(height: 12),
                      Text(c.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats + join
                  Row(
                    children: [
                      _statPill(Icons.people_outline, '${widget.community.memberCount} members', AppColors.textMuted),
                      const SizedBox(width: 10),
                      _statPill(Icons.category_outlined, c.category, AppColors.textMuted),
                      const Spacer(),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isJoined ? AppColors.card : c.accentColor,
                            foregroundColor: _isJoined ? AppColors.textSecondary : Colors.white,
                            side: _isJoined ? const BorderSide(color: AppColors.border) : BorderSide.none,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          onPressed: () => setState(() => _isJoined = !_isJoined),
                          child: Text(_isJoined ? 'Joined ✓' : 'Join', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 20),

                  // About
                  const Text('About', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(c.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),

                  const SizedBox(height: 24),

                  // Upcoming events in this community
                  const Text('Upcoming Events', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 12),
                  _eventTile('Monthly Meetup', 'Aug 2, 6:00 PM', 24, c.accentColor),
                  _eventTile('Workshop: Building with AI', 'Aug 9, 10:00 AM', 48, c.accentColor),

                  const SizedBox(height: 24),

                  // Members
                  const Text('Members', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 12),
                  _membersRow(),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      // Action bar at bottom
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('Community Chat'),
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.share_outlined, size: 18),
              label: const Text('Share'),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _statPill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _eventTile(String title, String time, int going, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.event_outlined, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14)),
                const SizedBox(height: 2),
                Text(time, style: TextStyle(color: accent, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$going going', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              const SizedBox(height: 4),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
                onPressed: () {},
                child: const Text('RSVP'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _membersRow() {
    final colors = [AppColors.questBlue, AppColors.emerald, AppColors.auroraPurple, AppColors.amber];
    final initials = ['AL', 'MK', 'SR', 'JD'];
    return Row(
      children: [
        ...List.generate(4, (i) => Transform.translate(
          offset: Offset(i * -10.0, 0),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: colors[i % colors.length],
            child: Text(initials[i], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        )),
        const SizedBox(width: 4),
        Text('+ ${widget.community.memberCount - 4} more', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ],
    );
  }
}
