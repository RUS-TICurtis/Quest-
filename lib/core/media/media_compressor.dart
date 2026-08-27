import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:v_video_compressor/v_video_compressor.dart';
import 'media_purpose.dart';

class MediaCompressor {
  static final _videoCompressor = VVideoCompressor();

  /// Compresses an image based on its purpose
  static Future<File?> compressImage(File file, MediaPurpose purpose) async {
    final targetPath = '${file.parent.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    int quality;
    int minWidth;
    int minHeight;

    switch (purpose) {
      case MediaPurpose.chat:
        quality = 70;
        minWidth = 1080;
        minHeight = 1080;
        break;
      case MediaPurpose.profile:
        quality = 85;
        minWidth = 512;
        minHeight = 512;
        break;
      case MediaPurpose.feed:
        quality = 80;
        minWidth = 1080;
        minHeight = 1920;
        break;
    }

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: quality,
      minWidth: minWidth,
      minHeight: minHeight,
    );

    return result != null ? File(result.path) : null;
  }

  /// Compresses a video based on its intended purpose.
  static Future<File?> compressVideo(File file, MediaPurpose purpose) async {
    try {
      VVideoCompressionConfig config;
      switch (purpose) {
        case MediaPurpose.chat:
          config = const VVideoCompressionConfig.low();
          break;
        case MediaPurpose.feed:
          config = const VVideoCompressionConfig.medium();
          break;
        case MediaPurpose.profile:
          config = const VVideoCompressionConfig.low();
          break;
      }
      
      debugPrint('Starting video compression with config: $config');
      final result = await _videoCompressor.compressVideo(
        file.absolute.path,
        config,
        onProgress: (progress) {
          debugPrint('Video compression progress: ${(progress * 100).toStringAsFixed(1)}%');
        },
      );
      
      if (result != null) {
        debugPrint('Video compression completed. Output: ${result.compressedFilePath}');
        return File(result.compressedFilePath);
      }
    } catch (e) {
      debugPrint('Error compressing video: $e');
    }
    
    debugPrint('Falling back to original video file.');
    return file; // Return original if compression fails
  }
}
