import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;

/// Manages image uploads to ImageKit via server-side signed authentication.
///
/// NOTE: The client NEVER holds `IMAGEKIT_PRIVATE_KEY`.
/// HMAC signatures are generated exclusively by `sign-media-upload`.
class ImageKitService {
  final Dio _dio;
  final SupabaseClient _supabase;

  ImageKitService({Dio? dio, SupabaseClient? supabase})
      : _dio = dio ?? Dio(),
        _supabase = supabase ?? Supabase.instance.client;

  /// Uploads an image File to ImageKit using server-provided auth signature.
  Future<String?> uploadImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final fileName = file.path.split('/').last.split('\\').last;
      return await uploadImageBytes(bytes, filename: fileName);
    } catch (e) {
      debugPrint('[ImageKitService] uploadImage error: $e');
      return null;
    }
  }

  /// Uploads image bytes to ImageKit using server-provided auth signature.
  Future<String?> uploadImageBytes(
    Uint8List bytes, {
    String? filename,
  }) async {
    try {
      // 1. Fetch server-signed authorization parameters
      final signResponse = await _supabase.functions.invoke(
        'sign-media-upload',
        body: {'provider': 'imagekit'},
      );

      if (signResponse.status != 200 || signResponse.data == null) {
        final err = signResponse.data is Map ? signResponse.data['error'] : 'Unknown error';
        debugPrint('[ImageKitService] Failed to obtain upload signature: $err');
        return null;
      }

      final signData = signResponse.data as Map<String, dynamic>;
      final uploadUrl = signData['upload_url'] as String;
      final publicKey = signData['public_key'] as String;
      final token = signData['token'] as String;
      final expire = signData['expire'] as String;
      final signature = signData['signature'] as String;

      final safeFileName = filename ?? 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // 2. Execute upload with server-authorized signature
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: safeFileName),
        'fileName': safeFileName,
        'publicKey': publicKey,
        'signature': signature,
        'expire': expire,
        'token': token,
      });

      final response = await _dio.post(
        uploadUrl,
        data: formData,
        onSendProgress: (int sent, int total) {
          if (total > 0) {
            debugPrint(
              'ImageKit Upload progress: ${(sent / total * 100).toStringAsFixed(0)}%',
            );
          }
        },
      );

      if (response.statusCode == 200) {
        return response.data['url'] as String?;
      }
    } catch (e) {
      debugPrint('[ImageKitService] Upload Error: $e');
    }
    return null;
  }
}
