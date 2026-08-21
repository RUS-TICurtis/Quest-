import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quest/shared/widgets/quest_button.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quest/core/theme/app_colors_extension.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  final TextEditingController _nameController = TextEditingController();
  final List<String> _selectedArchetypes = [];

  final _archetypes = [
    {
      'id': 'creator',
      'label': 'Creator',
      'icon': Icons.brush_outlined,
      'desc': 'You build, design, and bring ideas to life.',
    },
    {
      'id': 'organizer',
      'label': 'Organizer',
      'icon': Icons.calendar_today_outlined,
      'desc': 'You bring people together and host events.',
    },
    {
      'id': 'connector',
      'label': 'Connector',
      'icon': Icons.link_outlined,
      'desc': 'You thrive on networking and linking people.',
    },
    {
      'id': 'explorer',
      'label': 'Explorer',
      'icon': Icons.explore_outlined,
      'desc': 'You seek new communities and experiences.',
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _nextStep() => setState(() => _step = (_step + 1).clamp(0, 2));
  void _prevStep() => setState(() => _step = (_step - 1).clamp(0, 2));

  void _toggleArchetype(String id) {
    setState(() {
      if (_selectedArchetypes.contains(id)) {
        _selectedArchetypes.remove(id);
      } else if (_selectedArchetypes.length < 2) {
        _selectedArchetypes.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Container(
              height: 3,
              color: context.colors.card,
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedFractionallySizedBox(
                  duration: Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  widthFactor: (_step + 1) / 3,
                  child: Container(color: context.colors.gold),
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 24,
                ),
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => SlideTransition(
                    position: Tween(
                      begin: Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: _buildStep(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _step1();
      case 1:
        return _step2();
      case 2:
        return _step3();
      default:
        return _step1();
    }
  }

  Widget _step1() {
    return Column(
      key: ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What should we call you?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: context.colors.textPrimary,
            height: 1.2,
          ),
        ),
        SizedBox(height: 12),
        Text(
          "Quest doesn't ask who you are. It asks who you're becoming.",
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 15,
            height: 1.5,
          ),
        ),
        SizedBox(height: 40),
        TextField(
          controller: _nameController,
          autofocus: true,
          style: TextStyle(color: context.colors.textPrimary, fontSize: 16),
          decoration: InputDecoration(hintText: 'Display name...'),
          onChanged: (_) => setState(() {}),
        ),
        Spacer(),
        QuestButton(
          label: 'Continue',
          isFullWidth: true,
          onPressed: _nameController.text.trim().isEmpty ? null : _nextStep,
        ),
      ],
    );
  }

  Widget _step2() {
    return Column(
      key: ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose your Archetypes',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: context.colors.textPrimary,
            height: 1.2,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Select up to two defining characteristics.',
          style: TextStyle(color: context.colors.textSecondary, fontSize: 15),
        ),
        SizedBox(height: 24),

        Expanded(
          child: ListView(
            children: _archetypes.map((a) {
              final isSelected = _selectedArchetypes.contains(a['id']);
              final isDisabled = !isSelected && _selectedArchetypes.length >= 2;
              return GestureDetector(
                onTap: isDisabled
                    ? null
                    : () => _toggleArchetype(a['id'] as String),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? context.colors.questBlue.withValues(alpha: 0.15)
                        : context.colors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? context.colors.questBlue
                          : context.colors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? context.colors.questBlue.withValues(alpha: 0.2)
                              : context.colors.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          a['icon'] as IconData,
                          color: isSelected
                              ? context.colors.questBlue
                              : context.colors.textMuted,
                          size: 22,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a['label'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? context.colors.textPrimary
                                    : context.colors.textSecondary,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              a['desc'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: context.colors.questBlue,
                          size: 22,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        Row(
          children: [
            QuestButton(
              label: 'Back',
              variant: QuestButtonVariant.ghost,
              onPressed: _prevStep,
            ),
            Spacer(),
            QuestButton(
              label: 'Continue',
              onPressed: _selectedArchetypes.isEmpty ? null : _nextStep,
            ),
          ],
        ),
      ],
    );
  }

  Widget _step3() {
    final archetypeLabels = _selectedArchetypes
        .map(
          (id) =>
              _archetypes.firstWhere((a) => a['id'] == id)['label'] as String,
        )
        .join(' & ');

    return Column(
      key: ValueKey('step3'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: context.colors.questBlue.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: context.colors.questBlue.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: context.colors.questBlue.withValues(alpha: 0.3),
                blurRadius: 30,
              ),
            ],
          ),
          child: Icon(
            Icons.auto_awesome,
            color: context.colors.questBlue,
            size: 42,
          ),
        ),
        SizedBox(height: 32),
        Text(
          'Identity Forged',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: context.colors.textPrimary,
            letterSpacing: -1,
          ),
        ),
        SizedBox(height: 16),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(
              fontSize: 16,
              color: context.colors.textSecondary,
              height: 1.6,
            ),
            children: [
              TextSpan(text: 'Welcome to Quest, '),
              TextSpan(
                text: _nameController.text.trim(),
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(text: '.\nYour journey as a '),
              TextSpan(
                text: archetypeLabels,
                style: TextStyle(
                  color: context.colors.questBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(text: ' begins now.'),
            ],
          ),
        ),
        SizedBox(height: 48),
        QuestButton(
          label: 'Enter Dashboard',
          isFullWidth: true,
          icon: Icons.arrow_forward,
          onPressed: () {
            HapticFeedback.lightImpact();
            context.go('/home');
          },
        ),
      ],
    );
  }
}
