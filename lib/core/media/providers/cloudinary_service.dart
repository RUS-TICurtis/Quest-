import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;

/// Manages media uploads to Cloudinary via server-side signed requests.
///
/// NOTE: The client NEVER holds `CLOUDINARY_API_SECRET`.
/// Upload signatures are issued exclusively by `sign-media-upload`.
class CloudinaryService {
  final Dio _dio;
  final SupabaseClient _supabase;

  CloudinaryService({Dio? dio, SupabaseClient? supabase})
      : _dio = dio ?? Dio(),
        _supabase = supabase ?? Supabase.instance.client;

  /// Uploads media bytes to Cloudinary.
  Future<String?> uploadMediaBytes(
    Uint8List bytes, {
    bool isVideo = false,
    String filename = 'media',
  }) async {
    try {
      // 1. Fetch server-signed upload parameters
      final signResponse = await _supabase.functions.invoke(
        'sign-media-upload',
        body: {'provider': 'cloudinary', 'is_video': isVideo},
      );

      if (signResponse.status != 200 || signResponse.data == null) {
        final err = signResponse.data is Map ? signResponse.data['error'] : 'Unknown error';
        debugPrint('[CloudinaryService] Failed to obtain upload signature: $err');
        return null;
      }

      final signData = signResponse.data as Map<String, dynamic>;
      final uploadUrl = signData['upload_url'] as String;
      final apiKey = signData['api_key'] as String;
      final timestamp = signData['timestamp'] as String;
      final signature = signData['signature'] as String;

      // 2. Perform direct upload with server-authorized signature
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: isVideo ? '$filename.mp4' : '$filename.jpg',
        ),
        'api_key': apiKey,
        'timestamp': timestamp,
        'signature': signature,
      });

      final response = await _dio.post(
        uploadUrl,
        data: formData,
        onSendProgress: (int sent, int total) {
          if (total > 0) {
            debugPrint(
              'Cloudinary Upload progress: ${(sent / total * 100).toStringAsFixed(0)}%',
            );
          }
        },
      );

      if (response.statusCode == 200) {
        return response.data['secure_url'] as String?;
      }
    } catch (e) {
      debugPrint('[CloudinaryService] Upload Error: $e');
    }
    return null;
  }

  /// Uploads media File to Cloudinary.
  Future<String?> uploadMedia(File file, {bool isVideo = false}) async {
    try {
      final bytes = await file.readAsBytes();
      final filename = file.path.split('/').last.split('\\').last;
      return await uploadMediaBytes(
        bytes,
        isVideo: isVideo,
        filename: filename,
      );
    } catch (e) {
      debugPrint('[CloudinaryService] Upload File Error: $e');
      return null;
    }
  }
}
