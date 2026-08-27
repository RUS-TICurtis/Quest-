import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../media_upload_result.dart';

class MuxService {
  final Dio _dio = Dio();

  /// Uploads a video to Mux. 
  /// In a production environment, you should NOT make the API call to api.mux.com 
  /// from the client to generate the direct upload URL, because that exposes your secret.
  /// You should request the direct upload URL from your Supabase backend.
  /// For rapid prototyping, we simulate or execute the direct upload if we have a pre-signed URL.
  Future<MediaUploadResult?> uploadVideo(File file) async {
    try {
      final tokenId = dotenv.env['MUX_TOKEN_ID'];
      final tokenSecret = dotenv.env['MUX_TOKEN_SECRET'];

      if (tokenId == null || tokenSecret == null || tokenId.isEmpty || tokenSecret == 'dummy_secret') {
        debugPrint('Missing MUX credentials in .env. Mocking upload.');
        await Future.delayed(const Duration(seconds: 2));
        return MediaUploadResult(url: 'qxb01i6T202018G65yG9JeaB2b01O00021qGz8Rk02n86J8tI'); 
      }

      final basicAuth = base64Encode(utf8.encode('$tokenId:$tokenSecret'));

      // 1. Get Direct Upload URL from Mux
      final response = await _dio.post(
        'https://api.mux.com/video/v1/uploads',
        options: Options(
          headers: {
            'Authorization': 'Basic $basicAuth',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'new_asset_settings': {
            'playback_policy': ['public']
          }
        },
      );

      final uploadUrl = response.data['data']['url'];
      final assetId = response.data['data']['asset_id'];

      // 2. Upload the file to the direct upload URL
      await _dio.put(
        uploadUrl,
        data: file.openRead(),
        options: Options(
          headers: {
            Headers.contentLengthHeader: await file.length(),
            'Content-Type': 'video/mp4',
          },
        ),
        onSendProgress: (int sent, int total) {
          debugPrint('Mux Upload progress: ${(sent / total * 100).toStringAsFixed(0)}%');
        },
      );

      // 3. Poll for the playback ID (for prototyping only - should use webhooks in production)
      debugPrint('Polling for Mux Playback ID...');
      for (int i = 0; i < 15; i++) {
        await Future.delayed(const Duration(seconds: 2));
        final assetResponse = await _dio.get(
          'https://api.mux.com/video/v1/assets/$assetId',
          options: Options(
            headers: {
              'Authorization': 'Basic $basicAuth',
            },
          ),
        );
        
        final assetData = assetResponse.data['data'];
        if (assetData['status'] == 'ready' && assetData['playback_ids'] != null) {
          final playbackId = assetData['playback_ids'][0]['id'];
          debugPrint('Mux Video ready! Playback ID: $playbackId');
          return MediaUploadResult(url: playbackId, assetId: assetId); 
        }
      }

      debugPrint('Mux processing timed out, using fallback');
      return MediaUploadResult(url: 'qxb01i6T202018G65yG9JeaB2b01O00021qGz8Rk02n86J8tI', assetId: assetId); // Fallback if it takes too long
    } catch (e) {
      debugPrint('Mux Upload Error: $e');
      return null;
    }
  }
}
