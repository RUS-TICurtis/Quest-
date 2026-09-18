import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quest/core/media/media_purpose.dart';
import 'package:quest/core/media/media_service_gateway.dart';
import 'package:quest/core/theme/app_colors_extension.dart';
import 'package:quest/features/identity/profile/data/user_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;

  bool _isLoading = false;
  Uint8List? _selectedImageBytes;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider).value ?? UserState.initial();
    _nameController = TextEditingController(text: user.name);
    _usernameController = TextEditingController(text: user.username ?? '');
    _bioController = TextEditingController(text: user.bio ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    HapticFeedback.lightImpact();
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      HapticFeedback.mediumImpact();
      String? newAvatarUrl;

      if (_selectedImageBytes != null) {
        newAvatarUrl = await MediaServiceGateway.uploadImageBytes(
          _selectedImageBytes!,
          MediaPurpose.profile,
        );
      }

      final userNotifier = ref.read(userProvider.notifier);
      final currentUser = ref.read(userProvider).value ?? UserState.initial();

      // Recompute initials from the new name so avatar updates immediately
      final trimmedName = _nameController.text.trim();
      final nameParts =
          trimmedName.split(' ').where((p) => p.isNotEmpty).toList();
      final newInitials = nameParts.isEmpty
          ? 'Q'
          : nameParts.first[0].toUpperCase() +
              (nameParts.length > 1
                  ? nameParts.last[0].toUpperCase()
                  : '');

      final updatedUser = currentUser.copyWith(
        name: trimmedName,
        initials: newInitials,
        username: _usernameController.text.trim().replaceAll('@', ''),
        bio: _bioController.text.trim(),
        avatarUrl: newAvatarUrl ?? currentUser.avatarUrl,
      );

      await userNotifier.updateProfile(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully!'),
            backgroundColor: context.colors.emerald,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: context.colors.crimson,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider).value ?? UserState.initial();
    final authUser = Supabase.instance.client.auth.currentUser;
    final email = authUser?.email ?? 'Not connected';

    ImageProvider? avatarImage;
    if (_selectedImageBytes != null) {
      avatarImage = MemoryImage(_selectedImageBytes!);
    } else if (userState.avatarUrl != null && userState.avatarUrl!.isNotEmpty) {
      avatarImage = NetworkImage(userState.avatarUrl!);
    }

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.colors.questBlue,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: Text(
                'Save',
                style: TextStyle(
                  color: context.colors.questBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar Picker
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: context.colors.card,
                      backgroundImage: avatarImage,
                      child: avatarImage == null
                          ? Text(
                              userState.initials.isNotEmpty
                                  ? userState.initials
                                  : 'Q',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: context.colors.textPrimary,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.colors.questBlue,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.colors.background,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: context.colors.questBlue.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Change Profile Photo',
                style: TextStyle(
                  color: context.colors.questBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),

              // Full Name Field
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: context.colors.textPrimary),
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: TextStyle(color: context.colors.textMuted),
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: context.colors.questBlue,
                  ),
                  filled: true,
                  fillColor: context.colors.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: context.colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: context.colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: context.colors.questBlue,
                      width: 2,
                    ),
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Name cannot be empty'
                    : null,
              ),
              const SizedBox(height: 18),

              // Username Field
              TextFormField(
                controller: _usernameController,
                style: TextStyle(color: context.colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(color: context.colors.textMuted),
                  prefixText: '@',
                  prefixStyle: TextStyle(
                    color: context.colors.questBlue,
                    fontWeight: FontWeight.bold,
                  ),
                  prefixIcon: Icon(
                    Icons.alternate_email,
                    color: context.colors.questBlue,
                  ),
                  filled: true,
                  fillColor: context.colors.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: context.colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: context.colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: context.colors.questBlue,
                      width: 2,
                    ),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Username cannot be empty';
                  }
                  if (val.trim().contains(' ')) {
                    return 'Username cannot contain spaces';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Bio Field
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                maxLength: 150,
                style: TextStyle(color: context.colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Bio',
                  alignLabelWithHint: true,
                  labelStyle: TextStyle(color: context.colors.textMuted),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 50),
                    child: Icon(Icons.notes, color: context.colors.questBlue),
                  ),
                  filled: true,
                  fillColor: context.colors.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: context.colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: context.colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: context.colors.questBlue,
                      width: 2,
                    ),
                  ),
                  counterStyle: TextStyle(
                    color: context.colors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Account Email (Read-Only)
              TextFormField(
                initialValue: email,
                readOnly: true,
                style: TextStyle(color: context.colors.textMuted),
                decoration: InputDecoration(
                  labelText: 'Account Email',
                  labelStyle: TextStyle(color: context.colors.textMuted),
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: context.colors.textMuted,
                  ),
                  suffixIcon: Icon(
                    Icons.lock_outline,
                    color: context.colors.textMuted,
                    size: 18,
                  ),
                  filled: true,
                  fillColor: context.colors.card.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: context.colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: context.colors.border),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
