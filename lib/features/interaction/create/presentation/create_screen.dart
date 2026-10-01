import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quest/core/theme/app_colors_extension.dart';

class CreateScreen extends ConsumerStatefulWidget {
  const CreateScreen({super.key});

  @override
  ConsumerState<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends ConsumerState<CreateScreen>
    with WidgetsBindingObserver {
  int _selectedOptionIndex = 1; // Start with Image by default so camera opens
  final List<String> _options = ['Text', 'Image', 'Vlog'];

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isRecording = false;

  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
      _isCameraInitialized = false;
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        final controller = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: true,
        );
        await controller.initialize();
        if (!mounted) {
          controller.dispose();
          return;
        }
        _cameraController = controller;
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  void _disposeCamera() {
    _cameraController?.dispose();
    _cameraController = null;
    _isCameraInitialized = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final file = await picker.pickMedia(); // Allows both images and videos
    if (file != null) {
      HapticFeedback.lightImpact();
      if (!mounted) return;
      _disposeCamera(); // Free up camera when navigating away
      await context.push('/share-experience', extra: file.path);
      if (mounted && _selectedOptionIndex == 1) {
        _initCamera();
      }
    }
  }

  void _onOptionSelected(int index) {
    HapticFeedback.lightImpact();
    if (index == 0) {
      // Text mode
      _disposeCamera();
    } else {
      // Image or Vlog mode
      if (!_isCameraInitialized) {
        _initCamera();
      }
    }
    setState(() {
      _selectedOptionIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTextMode = _selectedOptionIndex == 0;

    return Scaffold(
      backgroundColor: Colors.black, // Camera background
      body: Stack(
        children: [
          // Content Area (Camera or Text)
          Positioned.fill(
            child: isTextMode ? _buildTextMode() : _buildCameraMode(),
          ),

          // Controls at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Options List (Text, Image, Vlog)
                SizedBox(
                  height: 30,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    itemCount: _options.length,
                    itemBuilder: (context, index) {
                      final isSelected = index == _selectedOptionIndex;
                      return GestureDetector(
                        onTap: () => _onOptionSelected(index),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          child: Text(
                            _options[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white54,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: isSelected ? 15 : 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 24),

                // Shutter / Action Button
                GestureDetector(
                  onTap: () async {
                    HapticFeedback.heavyImpact();
                    if (!isTextMode && _isCameraInitialized) {
                      if (_selectedOptionIndex == 2) {
                        // Vlog mode
                        if (_isRecording) {
                          try {
                            final file = await _cameraController!.stopVideoRecording();
                            setState(() => _isRecording = false);
                            if (!context.mounted) return;
                            _disposeCamera();
                            await context.push('/share-experience', extra: file.path);
                            if (mounted) _initCamera();
                          } catch (e) {
                            debugPrint('Error stopping video recording: $e');
                          }
                        } else {
                          try {
                            await _cameraController!.startVideoRecording();
                            setState(() => _isRecording = true);
                          } catch (e) {
                            debugPrint('Error starting video recording: $e');
                          }
                        }
                      } else {
                        // Image mode
                        try {
                          final file = await _cameraController!.takePicture();
                          if (!context.mounted) return;
                          _disposeCamera();
                          await context.push(
                            '/share-experience',
                            extra: file.path,
                          );
                          if (mounted) _initCamera();
                        } catch (e) {
                          debugPrint('Error taking picture: $e');
                        }
                      }
                    } else if (isTextMode) {
                      if (!context.mounted) return;
                      context.push(
                        '/share-experience',
                        extra: _textController.text,
                      );
                    }
                  },
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _isRecording ? 32 : 56,
                        height: _isRecording ? 32 : 56,
                        decoration: BoxDecoration(
                          color: _selectedOptionIndex == 2
                              ? Colors.red
                              : Colors.white,
                          borderRadius: BorderRadius.circular(_isRecording ? 8 : 28),
                        ),
                        child: isTextMode
                            ? const Icon(Icons.arrow_forward, color: Colors.black)
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Gallery Button (top left or bottom right)
          if (!isTextMode)
            Positioned(
              left: 24,
              bottom: 50,
              child: IconButton(
                icon: Icon(Icons.photo_library, color: Colors.white, size: 32),
                onPressed: _pickFromGallery,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraMode() {
    if (!_isCameraInitialized || _cameraController == null) {
      return Center(child: CircularProgressIndicator(color: Colors.white));
    }

    // Scale the camera preview to fill the screen
    return Transform.scale(
      scale: 1.0,
      child: Center(child: CameraPreview(_cameraController!)),
    );
  }

  Widget _buildTextMode() {
    return Container(
      color: context.colors.background,
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _textController,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'What\'s on your mind?',
                hintStyle: TextStyle(
                  color: context.colors.textMuted,
                  fontSize: 28,
                ),
                border: InputBorder.none,
              ),
            ),
            SizedBox(height: 32),
            // GIF Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.surface,
                foregroundColor: context.colors.questBlue,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: context.colors.border),
                ),
              ),
              icon: Icon(Icons.gif_box),
              label: Text('Add GIF'),
              onPressed: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('GIF Picker coming soon')),
                );
              },
            ),
            SizedBox(height: 100), // Space for bottom controls
          ],
        ),
      ),
    );
  }
}
