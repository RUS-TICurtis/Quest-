import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quest/core/theme/app_colors.dart';
import 'package:quest/core/theme/app_colors_extension.dart';
import 'package:quest/features/interaction/create/data/models/create_submission_payload.dart';

class CreateScreen extends ConsumerStatefulWidget {
  const CreateScreen({super.key});

  @override
  ConsumerState<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends ConsumerState<CreateScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  int _selectedOptionIndex = 1; // 0 = Text, 1 = Photo, 2 = Vlog
  final List<String> _options = ['Text', 'Photo', 'Vlog'];

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _isRecording = false;
  String? _cameraErrorMessage;

  // Flash state
  FlashMode _flashMode = FlashMode.off;

  // Video recording timer
  Timer? _recordingTimer;
  int _recordingDurationSeconds = 0;
  static const int _maxRecordingSeconds = 60;

  // Text mode state
  final TextEditingController _textController = TextEditingController();
  int _selectedGradientIndex = 0;
  final List<List<Color>> _textGradients = [
    [const Color(0xFF2563EB), const Color(0xFF7C3AED)], // Quest Blue to Aurora Purple
    [const Color(0xFF0F172A), const Color(0xFF1E293B)], // Midnight Slate
    [const Color(0xFF7C3AED), const Color(0xFFDB2777)], // Aurora to Magenta
    [const Color(0xFF059669), const Color(0xFF0D9488)], // Emerald to Teal
    [const Color(0xFFD97706), const Color(0xFFDC2626)], // Amber to Crimson
  ];

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.colors.crimson,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCameraWithIndex(0);
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
      _initCameraWithIndex(_selectedCameraIndex);
    }
  }

  Future<void> _initCameraWithIndex(int cameraIndex) async {
    setState(() {
      _cameraErrorMessage = null;
    });
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isCameraInitialized = false;
          _cameraErrorMessage = 'No camera detected on this device.';
        });
        return;
      }

      final targetIndex = (cameraIndex < _cameras!.length) ? cameraIndex : 0;
      _selectedCameraIndex = targetIndex;

      // Dispose existing controller if reinitializing (e.g. on flip)
      await _cameraController?.dispose();

      CameraController controller;
      try {
        controller = CameraController(
          _cameras![_selectedCameraIndex],
          ResolutionPreset.high,
          enableAudio: !kIsWeb,
        );
        await controller.initialize();
      } catch (firstErr) {
        debugPrint(
          '[CreateScreen] Primary camera init notice ($firstErr), attempting low-overhead fallback…',
        );
        controller = CameraController(
          _cameras![_selectedCameraIndex],
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await controller.initialize();
      }

      if (!mounted) {
        controller.dispose();
        return;
      }

      _cameraController = controller;
      _flashMode = FlashMode.off;
      try {
        await controller.setFlashMode(_flashMode);
      } catch (_) {}

      setState(() {
        _isCameraInitialized = true;
        _cameraErrorMessage = null;
      });
    } on CameraException catch (e) {
      debugPrint('CameraException: ${e.code} - ${e.description}');
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = false;
        if (e.code == 'CameraAccessDenied' ||
            e.code == 'CameraAccessDeniedWithoutPrompt' ||
            e.code == 'CameraAccessRestricted') {
          _cameraErrorMessage =
              'Camera access was denied. Please enable camera permissions in browser/device settings.';
        } else if (e.code == 'AudioAccessDenied') {
          _cameraErrorMessage =
              'Microphone access was denied. Please enable microphone permissions in settings.';
        } else if (e.code == 'cameraAbort') {
          _cameraErrorMessage =
              'Camera access was interrupted or is currently in use by another tab/app. Tap "Try Again" or create a Text experience.';
        } else {
          _cameraErrorMessage = 'Camera error: ${e.description ?? e.code}';
        }
      });
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = false;
        _cameraErrorMessage = 'Unable to initialize camera ($e).';
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    HapticFeedback.lightImpact();
    final nextIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    await _initCameraWithIndex(nextIndex);
  }

  Future<void> _toggleFlash() async {
    if (!_isCameraInitialized || _cameraController == null) return;
    HapticFeedback.selectionClick();

    FlashMode nextMode;
    switch (_flashMode) {
      case FlashMode.off:
        nextMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        nextMode = FlashMode.torch;
        break;
      case FlashMode.torch:
      case FlashMode.always:
        nextMode = FlashMode.off;
        break;
    }

    try {
      await _cameraController!.setFlashMode(nextMode);
      setState(() {
        _flashMode = nextMode;
      });
    } catch (e) {
      debugPrint('Error changing flash mode: $e');
    }
  }

  void _disposeCamera() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _cameraController?.dispose();
    _cameraController = null;
    _isCameraInitialized = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordingTimer?.cancel();
    _cameraController?.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final file = await picker.pickMedia();
    if (file != null) {
      HapticFeedback.lightImpact();
      if (!mounted) return;
      _disposeCamera();

      final isVideo = file.path.toLowerCase().endsWith('.mp4') ||
          file.path.toLowerCase().endsWith('.mov') ||
          file.path.toLowerCase().endsWith('.avi');

      final payload = CreateSubmissionPayload(
        mediaType: isVideo ? CreateMediaType.video : CreateMediaType.image,
        mediaPath: file.path,
      );

      await context.push('/share-experience', extra: payload);
      if (mounted && _selectedOptionIndex != 0) {
        _initCameraWithIndex(_selectedCameraIndex);
      }
    }
  }

  void _onOptionSelected(int index) {
    HapticFeedback.selectionClick();
    if (index == 0) {
      // Text mode
      _disposeCamera();
    } else {
      // Photo or Vlog mode
      if (!_isCameraInitialized) {
        _initCameraWithIndex(_selectedCameraIndex);
      }
    }
    setState(() {
      _selectedOptionIndex = index;
    });
  }

  void _startRecordingTimer() {
    _recordingDurationSeconds = 0;
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _recordingDurationSeconds++;
      });
      if (_recordingDurationSeconds >= _maxRecordingSeconds) {
        _stopVideoRecording();
      }
    });
  }

  Future<void> _startVideoRecording() async {
    if (!_isCameraInitialized || _cameraController == null) return;
    try {
      await _cameraController!.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
      _startRecordingTimer();
      HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('Error starting video recording: $e');
      _showError('Failed to start recording: $e');
    }
  }

  Future<void> _stopVideoRecording() async {
    if (!_isCameraInitialized || _cameraController == null || !_isRecording) {
      return;
    }
    _recordingTimer?.cancel();
    _recordingTimer = null;
    HapticFeedback.heavyImpact();

    try {
      final file = await _cameraController!.stopVideoRecording();
      setState(() => _isRecording = false);
      if (!mounted) return;
      _disposeCamera();

      final payload = CreateSubmissionPayload(
        mediaType: CreateMediaType.video,
        mediaPath: file.path,
      );

      await context.push('/share-experience', extra: payload);
      if (mounted && _selectedOptionIndex != 0) {
        _initCameraWithIndex(_selectedCameraIndex);
      }
    } catch (e) {
      debugPrint('Error stopping video recording: $e');
      _showError('Failed to save recorded video: $e');
      setState(() => _isRecording = false);
    }
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _cameraController == null) {
      _showError(
        _cameraErrorMessage ??
            'Camera is not ready. Try switching to text or picking from gallery.',
      );
      return;
    }
    HapticFeedback.heavyImpact();
    try {
      final file = await _cameraController!.takePicture();
      if (!mounted) return;
      _disposeCamera();

      final payload = CreateSubmissionPayload(
        mediaType: CreateMediaType.image,
        mediaPath: file.path,
      );

      await context.push('/share-experience', extra: payload);
      if (mounted && _selectedOptionIndex != 0) {
        _initCameraWithIndex(_selectedCameraIndex);
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
      _showError('Failed to capture photo: $e');
    }
  }

  void _submitTextExperience() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _showError('Please write your experience thoughts before continuing.');
      return;
    }
    HapticFeedback.lightImpact();

    final payload = CreateSubmissionPayload(
      mediaType: CreateMediaType.text,
      textContent: text,
      textBackgroundColor: _textGradients[_selectedGradientIndex].first,
    );

    context.push('/share-experience', extra: payload);
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _handleDismiss() {
    HapticFeedback.lightImpact();
    _disposeCamera();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTextMode = _selectedOptionIndex == 0;
    final isVlogMode = _selectedOptionIndex == 2;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Viewfinder or Text Canvas
          Positioned.fill(
            child: isTextMode ? _buildTextMode() : _buildCameraMode(),
          ),

          // 2. Top Controls Overlay
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Close / Dismiss button
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      onPressed: _handleDismiss,
                    ),

                    // Active Recording Badge in Vlog mode
                    if (_isRecording)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.4),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'REC ${_formatDuration(_recordingDurationSeconds)} / 01:00',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Right Camera Actions (Flash & Camera Switch)
                    if (!isTextMode && _isCameraInitialized)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Flash Toggle
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                _flashMode == FlashMode.torch
                                    ? Icons.flash_on
                                    : _flashMode == FlashMode.auto
                                    ? Icons.flash_auto
                                    : Icons.flash_off,
                                color: _flashMode != FlashMode.off
                                    ? AppColors.gold
                                    : Colors.white,
                                size: 20,
                              ),
                            ),
                            onPressed: _toggleFlash,
                          ),
                          const SizedBox(width: 4),

                          // Camera Flip
                          if (_cameras != null && _cameras!.length > 1)
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.flip_camera_ios,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              onPressed: _switchCamera,
                            ),
                        ],
                      )
                    else if (isTextMode)
                      const SizedBox(width: 48), // Balancing spacer
                  ],
                ),
              ),
            ),
          ),

          // 3. Bottom Controls (Mode Carousel + Shutter + Gallery)
          Positioned(
            left: 0,
            right: 0,
            bottom: 34,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mode Selector Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_options.length, (index) {
                      final isSelected = index == _selectedOptionIndex;
                      return GestureDetector(
                        onTap: () => _onOptionSelected(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? context.colors.questBlue
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            _options[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 13,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 24),

                // Shutter / Action Controls Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left: Gallery button or gradient cycle in text mode
                      if (!isTextMode)
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.photo_library_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          onPressed: _pickFromGallery,
                        )
                      else
                        // Gradient picker indicator
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedGradientIndex =
                                  (_selectedGradientIndex + 1) %
                                  _textGradients.length;
                            });
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: _textGradients[_selectedGradientIndex],
                              ),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.palette_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),

                      // Center: Shutter Button
                      GestureDetector(
                        onTap: () {
                          if (isTextMode) {
                            _submitTextExperience();
                          } else if (isVlogMode) {
                            if (_isRecording) {
                              _stopVideoRecording();
                            } else {
                              _startVideoRecording();
                            }
                          } else {
                            _takePicture();
                          }
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer ring with recording progress
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: CircularProgressIndicator(
                                value: isVlogMode && _isRecording
                                    ? _recordingDurationSeconds /
                                          _maxRecordingSeconds
                                    : 1.0,
                                strokeWidth: 4,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isVlogMode ? AppColors.crimson : Colors.white,
                                ),
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),

                            // Inner Shutter Trigger
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              width: _isRecording ? 36 : 64,
                              height: _isRecording ? 36 : 64,
                              decoration: BoxDecoration(
                                color: isVlogMode
                                    ? AppColors.crimson
                                    : isTextMode
                                    ? context.colors.questBlue
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(
                                  _isRecording ? 10 : 32,
                                ),
                              ),
                              child: isTextMode
                                  ? const Icon(
                                      Icons.arrow_forward,
                                      color: Colors.white,
                                      size: 28,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),

                      // Right Spacer for layout symmetry
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraMode() {
    if (_cameraErrorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.videocam_off_outlined,
                  size: 48,
                  color: context.colors.questBlue,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Camera Access Needed',
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _cameraErrorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.colors.textMuted,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.colors.textPrimary,
                      side: BorderSide(color: context.colors.border),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _initCameraWithIndex(_selectedCameraIndex);
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Try Again'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.questBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('Open Gallery'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (!_isCameraInitialized || _cameraController == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    // Edge-to-edge full viewfinder scaling
    return ClipRect(
      child: Transform.scale(
        scale: _cameraController!.value.aspectRatio,
        alignment: Alignment.center,
        child: Center(
          child: AspectRatio(
            aspectRatio: 1 / _cameraController!.value.aspectRatio,
            child: CameraPreview(_cameraController!),
          ),
        ),
      ),
    );
  }

  Widget _buildTextMode() {
    final gradient = _textGradients[_selectedGradientIndex];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _textController,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                height: 1.35,
              ),
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Share a real moment, victory, or insight…',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 32),

            // Tap palette pill hint
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.palette_outlined, color: Colors.white70, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Tap palette icon below to change theme',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 120), // Clearance for bottom controls
          ],
        ),
      ),
    );
  }
}
