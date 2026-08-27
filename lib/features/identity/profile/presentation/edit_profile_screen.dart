import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quest/core/media/media_purpose.dart';
import 'package:quest/core/theme/app_colors.dart';
import 'package:quest/features/identity/profile/data/user_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'package:quest/core/media/media_service_gateway.dart';

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
  late TextEditingController _ageController;
  
  bool _isLoading = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider).value ?? UserState.initial();
    _nameController = TextEditingController(text: user.name);
    _usernameController = TextEditingController(text: user.username ?? '');
    _bioController = TextEditingController(text: user.bio ?? '');
    _ageController = TextEditingController(text: 'Hidden'); // Read-only age
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    HapticFeedback.lightImpact();
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Avatar',
            toolbarColor: AppColors.background,
            toolbarWidgetColor: AppColors.textPrimary,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Avatar',
            aspectRatioLockEnabled: true,
            resetButtonHidden: true,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _selectedImage = File(croppedFile.path);
        });
      }
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

      if (_selectedImage != null) {
        final result = await MediaServiceGateway.uploadImage(_selectedImage!, MediaPurpose.profile);
        newAvatarUrl = result;
      }

      final userNotifier = ref.read(userProvider.notifier);
      final currentUser = ref.read(userProvider).value ?? UserState.initial();
      
      // Update local state (in a real app, this would make an API call to Supabase)
      userNotifier.updateProfile(
        currentUser.copyWith(
          name: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          bio: _bioController.text.trim(),
          avatarUrl: newAvatarUrl ?? currentUser.avatarUrl,
        ),
      );

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.emerald,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppColors.crimson,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        validator: validator,
        style: TextStyle(
          color: readOnly ? AppColors.textSecondary : AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.card,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.questBlue),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.crimson),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.crimson),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider).value ?? UserState.initial();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Edit Profile'),
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
                    color: AppColors.questBlue,
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
                  color: AppColors.questBlue,
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
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.border,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : (userState.avatarUrl != null
                              ? NetworkImage(userState.avatarUrl!)
                              : null) as ImageProvider?,
                      child: (_selectedImage == null && userState.avatarUrl == null)
                          ? Text(
                              userState.initials,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.questBlue,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.background,
                            width: 3,
                          ),
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
              _buildTextField(
                controller: _nameController,
                label: 'Name',
                validator: (val) => val == null || val.isEmpty ? 'Name cannot be empty' : null,
              ),
              _buildTextField(
                controller: _usernameController,
                label: 'Username',
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Username cannot be empty';
                  if (val.contains(' ')) return 'Username cannot contain spaces';
                  return null;
                },
              ),
              _buildTextField(
                controller: _bioController,
                label: 'Bio',
                maxLines: 3,
              ),
              _buildTextField(
                controller: _ageController,
                label: 'Age',
                readOnly: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
