import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../media_upload_result.dart';

/// Exception thrown when Mux signals quota exhaustion (HTTP 402 / 429).
class MuxQuotaException implements Exception {
  final String message;
  const MuxQuotaException(this.message);
  @override
  String toString() => 'MuxQuotaException: $message';
}

class MuxService {
  final Dio _dio = Dio();

  /// Uploads video bytes to Mux via a direct upload URL.
  ///
  /// Fixed polling strategy:
  /// 1. Create direct upload → receive `upload_id`.
  /// 2. PUT bytes to the signed upload URL.
  /// 3. Poll `GET /video/v1/uploads/$uploadId` until `status == 'asset_created'`
  ///    and `asset_id` is populated (asset_id is null until file processing begins).
  /// 4. Poll `GET /video/v1/assets/$assetId` until `status == 'ready'`.
  ///
  /// Throws [MuxQuotaException] on HTTP 402/429 so the gateway can fallback.
  Future<MediaUploadResult?> uploadVideoBytes(Uint8List bytes) async {
    final tokenId = dotenv.env['MUX_TOKEN_ID'];
    final tokenSecret = dotenv.env['MUX_TOKEN_SECRET'];

    if (tokenId == null ||
        tokenSecret == null ||
        tokenId.isEmpty ||
        tokenSecret == 'dummy_secret') {
      debugPrint('[MuxService] Missing credentials – returning mock result.');
      await Future.delayed(const Duration(seconds: 1));
      return MediaUploadResult(
        url: 'qxb01i6T202018G65yG9JeaB2b01O00021qGz8Rk02n86J8tI',
      );
    }

    final basicAuth = base64Encode(utf8.encode('$tokenId:$tokenSecret'));

    // ── Step 1: Create Direct Upload ──────────────────────────────────────
    late String uploadId;
    late String uploadUrl;

    try {
      final createResponse = await _dio.post(
        'https://api.mux.com/video/v1/uploads',
        options: Options(
          headers: {
            'Authorization': 'Basic $basicAuth',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'new_asset_settings': {
            'playback_policy': ['public'],
          },
          'cors_origin': '*',
        },
      );

      uploadId = createResponse.data['data']['id'] as String;
      uploadUrl = createResponse.data['data']['url'] as String;
      debugPrint('[MuxService] Direct upload created. upload_id=$uploadId');
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      if (statusCode == 402 || statusCode == 429) {
        throw MuxQuotaException(
          'Mux quota limit reached (HTTP $statusCode). Falling back to Cloudinary.',
        );
      }
      debugPrint('[MuxService] Error creating upload: $e');
      return null;
    }

    // ── Step 2: PUT bytes to the Direct Upload URL ────────────────────────
    try {
      await _dio.put(
        uploadUrl,
        data: Stream.fromIterable([bytes]),
        options: Options(
          headers: {
            Headers.contentLengthHeader: bytes.length,
            'Content-Type': 'video/mp4',
          },
        ),
        onSendProgress: (int sent, int total) {
          final pct = total > 0 ? (sent / total * 100).toStringAsFixed(0) : '?';
          debugPrint('[MuxService] Upload progress: $pct%');
        },
      );
      debugPrint('[MuxService] Bytes uploaded to Mux CDN.');
    } on DioException catch (e) {
      debugPrint('[MuxService] Error uploading bytes: $e');
      return null;
    }

    // ── Step 3: Poll /uploads/$uploadId until asset_id is available ───────
    String? assetId;
    debugPrint('[MuxService] Polling upload status for upload_id=$uploadId …');
    for (int i = 0; i < 20; i++) {
      await Future.delayed(const Duration(seconds: 3));
      try {
        final uploadResp = await _dio.get(
          'https://api.mux.com/video/v1/uploads/$uploadId',
          options: Options(headers: {'Authorization': 'Basic $basicAuth'}),
        );
        final uploadData = uploadResp.data['data'];
        final status = uploadData['status'] as String? ?? '';
        debugPrint('[MuxService] Upload status[$i]: $status');

        if (status == 'asset_created') {
          assetId = uploadData['asset_id'] as String?;
          if (assetId != null && assetId.isNotEmpty) {
            debugPrint('[MuxService] Asset created. asset_id=$assetId');
            break;
          }
        } else if (status == 'errored') {
          debugPrint('[MuxService] Mux upload errored. Triggering fallback.');
          return null;
        }
      } on DioException catch (e) {
        debugPrint('[MuxService] Poll upload error[$i]: $e');
      }
    }

    if (assetId == null) {
      debugPrint('[MuxService] Timed out waiting for asset_id. Returning null.');
      return null;
    }

    // ── Step 4: Poll /assets/$assetId until status == 'ready' ────────────
    debugPrint('[MuxService] Polling asset for asset_id=$assetId …');
    for (int i = 0; i < 20; i++) {
      await Future.delayed(const Duration(seconds: 3));
      try {
        final assetResp = await _dio.get(
          'https://api.mux.com/video/v1/assets/$assetId',
          options: Options(headers: {'Authorization': 'Basic $basicAuth'}),
        );
        final assetData = assetResp.data['data'];
        final status = assetData['status'] as String? ?? '';
        debugPrint('[MuxService] Asset status[$i]: $status');

        if (status == 'ready' && assetData['playback_ids'] != null) {
          final playbackId =
              assetData['playback_ids'][0]['id'] as String;
          debugPrint('[MuxService] Video ready! playback_id=$playbackId');
          return MediaUploadResult(url: playbackId, assetId: assetId);
        } else if (status == 'errored') {
          debugPrint('[MuxService] Asset processing failed.');
          return null;
        }
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode ?? 0;
        if (statusCode == 402 || statusCode == 429) {
          throw MuxQuotaException(
            'Mux quota reached during asset poll (HTTP $statusCode).',
          );
        }
        debugPrint('[MuxService] Poll asset error[$i]: $e');
      }
    }

    debugPrint('[MuxService] Asset not ready after polling. Returning null.');
    return null;
  }

  /// Uploads a local video [File] to Mux.
  Future<MediaUploadResult?> uploadVideo(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return await uploadVideoBytes(bytes);
    } catch (e) {
      debugPrint('[MuxService] uploadVideo error: $e');
      rethrow; // Let the gateway handle MuxQuotaException
    }
  }
}
