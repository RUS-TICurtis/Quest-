import 'package:flutter/foundation.dart';
import 'dart:io';
import 'media_purpose.dart';
import 'media_compressor.dart';
import 'providers/mux_service.dart';
import 'providers/cloudinary_service.dart';
import 'providers/imagekit_service.dart';
import 'media_upload_result.dart';

/// Callback used to report upload stage transitions to the UI layer.
typedef UploadStatusCallback = void Function(String statusMessage);

/// Routes media uploads to the correct cloud provider based on [MediaPurpose].
///
/// For feed videos, the pipeline is:
///   1. Compress locally.
///   2. Attempt Mux direct upload.
///   3. If Mux fails (quota, timeout, null result), fall back to Cloudinary.
class MediaServiceGateway {
  static final MuxService _muxService = MuxService();
  static final CloudinaryService _cloudinaryService = CloudinaryService();
  static final ImageKitService _imageKitService = ImageKitService();

  /// Uploads a video [File].
  ///
  /// [onStatus] receives human-readable stage labels for UI progress overlays.
  /// Returns [MediaUploadResult] with either a Mux playback ID or a Cloudinary URL,
  /// and [MediaUploadResult.usedFallback] == true when Cloudinary was used.
  static Future<MediaUploadResult?> uploadVideo(
    File file,
    MediaPurpose purpose, {
    UploadStatusCallback? onStatus,
  }) async {
    debugPrint('[MediaGateway] Starting video upload for purpose: $purpose');
    if (!kIsWeb) {
      debugPrint(
        '[MediaGateway] Original file size: ${await file.length()} bytes',
      );
    }

    // 1. Compress
    onStatus?.call('Compressing video…');
    final compressedFile = await MediaCompressor.compressVideo(file, purpose);
    final fileToUpload = compressedFile ?? file;

    if (compressedFile != null && !kIsWeb) {
      debugPrint(
        '[MediaGateway] Compressed size: ${await compressedFile.length()} bytes',
      );
    }

    // 2. Route
    switch (purpose) {
      case MediaPurpose.feed:
        return await _uploadFeedVideo(
          onStatus: onStatus,
          uploadFn: () => _muxService.uploadVideo(fileToUpload),
          fallbackFn: () => _cloudinaryService.uploadMedia(
            fileToUpload,
            isVideo: true,
          ),
        );
      case MediaPurpose.chat:
      case MediaPurpose.profile:
        onStatus?.call('Uploading…');
        final url = await _cloudinaryService.uploadMedia(
          fileToUpload,
          isVideo: true,
        );
        if (url != null) return MediaUploadResult(url: url);
        return null;
    }
  }

  /// Uploads video bytes directly (web / byte-based workflows).
  static Future<MediaUploadResult?> uploadVideoBytes(
    Uint8List bytes,
    MediaPurpose purpose, {
    UploadStatusCallback? onStatus,
  }) async {
    debugPrint(
      '[MediaGateway] Video bytes upload for purpose: $purpose (${bytes.length} bytes)',
    );

    switch (purpose) {
      case MediaPurpose.feed:
        return await _uploadFeedVideo(
          onStatus: onStatus,
          uploadFn: () => _muxService.uploadVideoBytes(bytes),
          fallbackFn: () => _cloudinaryService.uploadMediaBytes(
            bytes,
            isVideo: true,
          ),
        );
      case MediaPurpose.chat:
      case MediaPurpose.profile:
        onStatus?.call('Uploading…');
        final url = await _cloudinaryService.uploadMediaBytes(
          bytes,
          isVideo: true,
        );
        if (url != null) return MediaUploadResult(url: url);
        return null;
    }
  }

  // ── Private ────────────────────────────────────────────────────────────────

  /// Tries Mux first; falls back to Cloudinary on any failure or null result.
  static Future<MediaUploadResult?> _uploadFeedVideo({
    UploadStatusCallback? onStatus,
    required Future<MediaUploadResult?> Function() uploadFn,
    required Future<String?> Function() fallbackFn,
  }) async {
    // ── Attempt Mux ──────────────────────────────────────────────────────
    try {
      onStatus?.call('Uploading to Mux…');
      final muxResult = await uploadFn();

      if (muxResult != null) {
        debugPrint('[MediaGateway] Mux upload successful.');
        onStatus?.call('Finalizing…');
        return muxResult;
      }

      debugPrint('[MediaGateway] Mux returned null – falling back to Cloudinary.');
    } on MuxQuotaException catch (e) {
      debugPrint('[MediaGateway] $e – falling back to Cloudinary.');
    } catch (e) {
      debugPrint('[MediaGateway] Mux error: $e – falling back to Cloudinary.');
    }

    // ── Cloudinary Fallback ───────────────────────────────────────────────
    onStatus?.call('Switching to backup storage…');
    try {
      final cloudUrl = await fallbackFn();
      if (cloudUrl != null) {
        debugPrint('[MediaGateway] Cloudinary fallback successful: $cloudUrl');
        onStatus?.call('Finalizing…');
        return MediaUploadResult(url: cloudUrl, usedFallback: true);
      }
    } catch (e) {
      debugPrint('[MediaGateway] Cloudinary fallback error: $e');
    }

    debugPrint('[MediaGateway] Both providers failed. Returning null.');
    return null;
  }

  /// Uploads an image [File].
  static Future<String?> uploadImage(File file, MediaPurpose purpose) async {
    debugPrint('[MediaGateway] Image upload for purpose: $purpose');
    if (!kIsWeb) {
      debugPrint(
        '[MediaGateway] Original file size: ${await file.length()} bytes',
      );
    }

    final compressedFile = await MediaCompressor.compressImage(file, purpose);
    final fileToUpload = compressedFile ?? file;

    if (compressedFile != null && !kIsWeb) {
      debugPrint(
        '[MediaGateway] Compressed size: ${await compressedFile.length()} bytes',
      );
    }

    switch (purpose) {
      case MediaPurpose.feed:
        return await _imageKitService.uploadImage(fileToUpload);
      case MediaPurpose.chat:
        return await _cloudinaryService.uploadMedia(
          fileToUpload,
          isVideo: false,
        );
      case MediaPurpose.profile:
        return await _imageKitService.uploadImage(fileToUpload);
    }
  }

  /// Uploads image bytes directly.
  static Future<String?> uploadImageBytes(
    Uint8List bytes,
    MediaPurpose purpose,
  ) async {
    debugPrint(
      '[MediaGateway] Image bytes upload for purpose: $purpose (${bytes.length} bytes)',
    );
    return await _cloudinaryService.uploadMediaBytes(bytes, isVideo: false);
  }
}
