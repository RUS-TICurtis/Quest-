import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:quest/core/theme/app_colors_extension.dart';

class CreateScreen extends ConsumerStatefulWidget {
  const CreateScreen({super.key});

  @override
  ConsumerState<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends ConsumerState<CreateScreen> {
  int _selectedOptionIndex = 1; // Start with Image by default so camera opens
  final List<String> _options = ['Text', 'Image', 'Vlog'];
  
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }
  
  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: true,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
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
    _cameraController?.dispose();
    _textController.dispose();
    super.dispose();
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
            child: isTextMode
                ? _buildTextMode()
                : _buildCameraMode(),
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
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                      // Optionally simulate capturing a photo/video here
                      // final file = await _cameraController!.takePicture();
                    }
                    // Go to Share/Edit screen
                    context.push('/share-experience');
                  },
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _selectedOptionIndex == 2 ? Colors.red : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: isTextMode
                            ? Icon(Icons.arrow_forward, color: Colors.black)
                            : null,
                      ),
                    ),
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
    if (!_isCameraInitialized || _cameraController == null) {
      return Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    
    // Scale the camera preview to fill the screen
    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;
    return Transform.scale(
      scale: 1.0, // _cameraController!.value.aspectRatio / deviceRatio (often needs adjustment)
      child: Center(
        child: CameraPreview(_cameraController!),
      ),
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
