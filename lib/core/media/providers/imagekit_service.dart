import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class ImageKitService {
  final Dio _dio = Dio();

  /// Uploads an image to ImageKit.
  /// Generates the authentication signature client-side using the private key for rapid prototyping.
  Future<String?> uploadImage(File file) async {
    final publicKey = dotenv.env['IMAGEKIT_PUBLIC_KEY'];
    final privateKey = dotenv.env['IMAGEKIT_PRIVATE_KEY'];

    if (publicKey == null || privateKey == null) {
      debugPrint('Missing ImageKit keys in .env');
      return null;
    }

    try {
      // 1. Generate auth parameters
      final String token = DateTime.now().millisecondsSinceEpoch.toString();
      final int expire = (DateTime.now().millisecondsSinceEpoch / 1000).round() + 1800; // 30 mins
      
      // HMAC-SHA1 of (token + expire) using privateKey
      final String dataToSign = token + expire.toString();
      final hmacSha1 = Hmac(sha1, utf8.encode(privateKey));
      final Digest digest = hmacSha1.convert(utf8.encode(dataToSign));
      final String signature = digest.toString();

      // 2. Prepare upload
      final uploadUrl = 'https://upload.imagekit.io/api/v1/files/upload';
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
        'fileName': fileName,
        'publicKey': publicKey,
        'signature': signature,
        'expire': expire.toString(),
        'token': token,
        // 'useUniqueFileName': 'true', // optional
      });

      // 3. Execute upload
      final response = await _dio.post(
        uploadUrl,
        data: formData,
        onSendProgress: (int sent, int total) {
          debugPrint('ImageKit Upload progress: ${(sent / total * 100).toStringAsFixed(0)}%');
        },
      );

      if (response.statusCode == 200) {
        // Return the optimized URL provided by ImageKit
        return response.data['url'];
      }
    } catch (e) {
      debugPrint('ImageKit Upload Error: $e');
    }
    return null;
  }
}
