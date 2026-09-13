import 'package:flutter/foundation.dart';
import 'dart:io';
import 'media_purpose.dart';
import 'media_compressor.dart';
import 'providers/mux_service.dart';
import 'providers/cloudinary_service.dart';
import 'providers/imagekit_service.dart';

import 'media_upload_result.dart';

class MediaServiceGateway {
  static final MuxService _muxService = MuxService();
  static final CloudinaryService _cloudinaryService = CloudinaryService();
  static final ImageKitService _imageKitService = ImageKitService();

  /// Main entry point for uploading video.
  /// Compresses the video locally, then routes to the appropriate provider
  /// based on the MediaPurpose.
  static Future<MediaUploadResult?> uploadVideo(File file, MediaPurpose purpose) async {
    debugPrint('Starting video upload for purpose: $purpose');
    if (!kIsWeb) {
      debugPrint('Original file size: ${await file.length()} bytes');
    }

    // 1. Compress Video
    final compressedFile = await MediaCompressor.compressVideo(file, purpose);
    final fileToUpload = compressedFile ?? file;
    
    if (compressedFile != null && !kIsWeb) {
      debugPrint('Compressed file size: ${await compressedFile.length()} bytes');
    }

    // 2. Route to Provider
    switch (purpose) {
      case MediaPurpose.feed:
        return await _muxService.uploadVideo(fileToUpload);
      case MediaPurpose.chat:
        final url = await _cloudinaryService.uploadMedia(fileToUpload, isVideo: true);
        if (url != null) return MediaUploadResult(url: url);
        return null;
      case MediaPurpose.profile:
        final url = await _cloudinaryService.uploadMedia(fileToUpload, isVideo: true);
        if (url != null) return MediaUploadResult(url: url);
        return null;
    }
  }

  /// Uploads video bytes directly (used on Web and byte-based workflows).
  static Future<MediaUploadResult?> uploadVideoBytes(Uint8List bytes, MediaPurpose purpose) async {
    debugPrint('Starting video bytes upload for purpose: $purpose (size: ${bytes.length} bytes)');
    switch (purpose) {
      case MediaPurpose.feed:
        return await _muxService.uploadVideoBytes(bytes);
      case MediaPurpose.chat:
      case MediaPurpose.profile:
        final url = await _cloudinaryService.uploadMediaBytes(bytes, isVideo: true);
        if (url != null) return MediaUploadResult(url: url);
        return null;
    }
  }

  /// Main entry point for uploading images.
  /// Compresses the image locally, then routes to the appropriate provider
  /// based on the MediaPurpose.
  static Future<String?> uploadImage(File file, MediaPurpose purpose) async {
    debugPrint('Starting image upload for purpose: $purpose');
    if (!kIsWeb) {
      debugPrint('Original file size: ${await file.length()} bytes');
    }

    // 1. Compress Image
    final compressedFile = await MediaCompressor.compressImage(file, purpose);
    final fileToUpload = compressedFile ?? file;

    if (compressedFile != null && !kIsWeb) {
      debugPrint('Compressed file size: ${await compressedFile.length()} bytes');
    }

    // 2. Route to Provider
    switch (purpose) {
      case MediaPurpose.feed:
        return await _imageKitService.uploadImage(fileToUpload);
      case MediaPurpose.chat:
        return await _cloudinaryService.uploadMedia(fileToUpload, isVideo: false);
      case MediaPurpose.profile:
        return await _imageKitService.uploadImage(fileToUpload);
    }
  }

  /// Uploads image bytes directly (used on Web and byte-based workflows).
  static Future<String?> uploadImageBytes(Uint8List bytes, MediaPurpose purpose) async {
    debugPrint('Starting image bytes upload for purpose: $purpose (size: ${bytes.length} bytes)');
    // Cloudinary natively supports raw byte uploads across all platforms
    return await _cloudinaryService.uploadMediaBytes(bytes, isVideo: false);
  }
}
