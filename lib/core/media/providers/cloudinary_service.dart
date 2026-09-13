import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class CloudinaryService {
  final Dio _dio = Dio();

  /// Uploads media bytes to Cloudinary.
  Future<String?> uploadMediaBytes(Uint8List bytes, {bool isVideo = false, String filename = 'media'}) async {
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
    final apiKey = dotenv.env['CLOUDINARY_API_KEY'];
    final apiSecret = dotenv.env['CLOUDINARY_API_SECRET'];

    if (cloudName == null || cloudName.isEmpty) {
      debugPrint('Missing CLOUDINARY_CLOUD_NAME in .env');
      return 'https://res.cloudinary.com/demo/image/upload/sample.jpg';
    }

    try {
      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round().toString();
      
      // Signature generation: sha1(timestamp=xxx<api_secret>)
      final paramsToSign = 'timestamp=$timestamp$apiSecret';
      final signature = sha1.convert(utf8.encode(paramsToSign)).toString();

      final resourceType = isVideo ? 'video' : 'image';
      final uploadUrl = 'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload';

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: isVideo ? '$filename.mp4' : '$filename.jpg'),
        'api_key': apiKey,
        'timestamp': timestamp,
        'signature': signature,
      });

      final response = await _dio.post(
        uploadUrl,
        data: formData,
        onSendProgress: (int sent, int total) {
          debugPrint('Cloudinary Upload progress: ${(sent / total * 100).toStringAsFixed(0)}%');
        },
      );

      if (response.statusCode == 200) {
        return response.data['secure_url'];
      }
    } catch (e) {
      debugPrint('Cloudinary Upload Error: $e');
    }
    return null;
  }

  /// Uploads media File to Cloudinary.
  Future<String?> uploadMedia(File file, {bool isVideo = false}) async {
    try {
      final bytes = await file.readAsBytes();
      final filename = file.path.split('/').last.split('\\').last;
      return await uploadMediaBytes(bytes, isVideo: isVideo, filename: filename);
    } catch (e) {
      debugPrint('Cloudinary Upload File Error: $e');
      return null;
    }
  }
}
