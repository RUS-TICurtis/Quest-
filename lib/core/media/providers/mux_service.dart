import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Headers;
import '../media_upload_result.dart';

/// Exception thrown when Mux signals quota exhaustion (HTTP 402 / 429).
class MuxQuotaException implements Exception {
  final String message;
  const MuxQuotaException(this.message);
  @override
  String toString() => 'MuxQuotaException: $message';
}

/// Manages direct video uploads to Mux via Supabase Edge Function delegation.
///
/// NOTE: The client NEVER holds Mux API tokens (`MUX_TOKEN_ID`, `MUX_TOKEN_SECRET`).
/// The server signs and provisions direct upload URLs through `sign-media-upload`.
class MuxService {
  final Dio _dio;
  final SupabaseClient _supabase;

  MuxService({Dio? dio, SupabaseClient? supabase})
      : _dio = dio ?? Dio(),
        _supabase = supabase ?? Supabase.instance.client;

  /// Uploads video bytes to Mux via a server-generated direct upload URL.
  Future<MediaUploadResult?> uploadVideoBytes(Uint8List bytes) async {
    // ── Step 1: Request Direct Upload URL from Edge Function ──────────────────
    late String uploadUrl;
    late String uploadId;

    try {
      final response = await _supabase.functions.invoke(
        'sign-media-upload',
        body: {'provider': 'mux'},
      );

      if (response.status != 200 || response.data == null) {
        final errorMsg = response.data is Map ? response.data['error'] : 'Unknown error';
        debugPrint('[MuxService] Failed to obtain direct upload URL: $errorMsg');
        return null;
      }

      final data = response.data as Map<String, dynamic>;
      uploadUrl = data['upload_url'] as String;
      uploadId = data['upload_id'] as String;
      debugPrint('[MuxService] Direct upload URL obtained (upload_id: $uploadId)');
    } on FunctionException catch (e) {
      if (e.status == 402 || e.status == 429) {
        throw MuxQuotaException('Mux quota limit reached (${e.status}).');
      }
      debugPrint('[MuxService] Edge function error: $e');
      return null;
    } catch (e) {
      debugPrint('[MuxService] Error obtaining Mux upload URL: $e');
      return null;
    }

    // ── Step 2: PUT bytes directly to Mux CDN ──────────────────────────────
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
      final statusCode = e.response?.statusCode ?? 0;
      if (statusCode == 402 || statusCode == 429) {
        throw MuxQuotaException('Mux quota limit reached during upload ($statusCode).');
      }
      debugPrint('[MuxService] Error uploading bytes to Mux: $e');
      return null;
    }

    // ── Step 3: Poll Edge Function until asset is ready ─────────────────────
    debugPrint('[MuxService] Polling asset readiness for upload_id=$uploadId …');
    for (int i = 0; i < 20; i++) {
      await Future.delayed(const Duration(seconds: 3));
      try {
        final pollResp = await _supabase.functions.invoke(
          'sign-media-upload',
          body: {
            'provider': 'mux',
            'action': 'check_mux',
            'upload_id': uploadId,
          },
        );

        if (pollResp.status == 200 && pollResp.data is Map) {
          final data = pollResp.data as Map<String, dynamic>;
          final status = data['status'] as String? ?? '';
          debugPrint('[MuxService] Asset readiness poll[$i]: $status');

          if (status == 'ready' && data['playback_id'] != null) {
            final playbackId = data['playback_id'] as String;
            final assetId = data['asset_id'] as String?;
            debugPrint('[MuxService] Video ready! playback_id=$playbackId');
            return MediaUploadResult(url: playbackId, assetId: assetId);
          } else if (status == 'errored') {
            debugPrint('[MuxService] Mux asset processing failed.');
            return null;
          }
        }
      } catch (e) {
        debugPrint('[MuxService] Poll error[$i]: $e');
      }
    }

    debugPrint('[MuxService] Asset not ready after polling timeout.');
    return null;
  }

  /// Uploads a local video [File] to Mux.
  Future<MediaUploadResult?> uploadVideo(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return await uploadVideoBytes(bytes);
    } catch (e) {
      debugPrint('[MuxService] uploadVideo error: $e');
      rethrow;
    }
  }
}
