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
        title: Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
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
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton(
                onPressed: _saveProfile,
                style: TextButton.styleFrom(
                  foregroundColor: context.colors.questBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
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
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: context.colors.questBlue.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 64,
                        backgroundColor: context.colors.card,
                        backgroundImage: avatarImage,
                        child: avatarImage == null
                            ? Text(
                                userState.initials.isNotEmpty
                                    ? userState.initials
                                    : 'Q',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  color: context.colors.textPrimary,
                                ),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.colors.questBlue,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.colors.background,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Change Profile Photo',
                style: TextStyle(
                  color: context.colors.questBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 48),

              // Form Fields
              Container(
                decoration: BoxDecoration(
                  color: context.colors.card,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline_rounded,
                      textCapitalization: TextCapitalization.words,
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Name cannot be empty'
                          : null,
                    ),
                    Divider(height: 1, color: context.colors.border),
                    _buildTextField(
                      controller: _usernameController,
                      label: 'Username',
                      icon: Icons.alternate_email_rounded,
                      prefixText: '@',
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
                    Divider(height: 1, color: context.colors.border),
                    _buildTextField(
                      controller: _bioController,
                      label: 'Bio',
                      icon: Icons.notes_rounded,
                      maxLines: 3,
                      maxLength: 150,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Account Email (Read-Only)
              Container(
                decoration: BoxDecoration(
                  color: context.colors.card.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _buildTextField(
                  initialValue: email,
                  label: 'Account Email',
                  icon: Icons.email_outlined,
                  readOnly: true,
                  showBorder: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    String? initialValue,
    required String label,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
    String? prefixText,
    bool readOnly = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    bool showBorder = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextFormField(
        controller: controller,
        initialValue: initialValue,
        readOnly: readOnly,
        maxLines: maxLines,
        maxLength: maxLength,
        textCapitalization: textCapitalization,
        style: TextStyle(
          color: readOnly ? context.colors.textMuted : context.colors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: context.colors.textMuted,
            fontWeight: FontWeight.w400,
          ),
          prefixText: prefixText,
          prefixStyle: TextStyle(
            color: context.colors.questBlue,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          prefixIcon: Icon(
            icon,
            color: readOnly ? context.colors.textMuted : context.colors.questBlue,
            size: 22,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          counterStyle: TextStyle(
            color: context.colors.textMuted,
            fontSize: 12,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        validator: validator,
      ),
    );
  }
}
