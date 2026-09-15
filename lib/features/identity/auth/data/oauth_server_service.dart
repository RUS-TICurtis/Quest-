import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OAuthAuthorizationDetails {
  final String authorizationId;
  final String clientName;
  final String? clientLogoUrl;
  final String redirectUri;
  final List<String> scopes;
  final String? directRedirectUrl;

  const OAuthAuthorizationDetails({
    required this.authorizationId,
    required this.clientName,
    this.clientLogoUrl,
    required this.redirectUri,
    required this.scopes,
    this.directRedirectUrl,
  });

  factory OAuthAuthorizationDetails.fromJson(
    String authId,
    Map<String, dynamic> json,
  ) {
    final client = json['client'] as Map<String, dynamic>? ?? {};
    final rawScope = json['scope'] as String? ?? '';
    final scopesList = rawScope
        .split(' ')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return OAuthAuthorizationDetails(
      authorizationId: authId,
      clientName: (client['name'] as String?)?.isNotEmpty == true
          ? client['name'] as String
          : 'Third-Party Application',
      clientLogoUrl: client['logo_uri'] as String?,
      redirectUri: json['redirect_uri'] as String? ?? '',
      scopes: scopesList.isNotEmpty ? scopesList : ['openid', 'profile'],
      directRedirectUrl: json['redirect_url'] as String?,
    );
  }

  /// Demo preview fallback for testing consent screen UI locally
  factory OAuthAuthorizationDetails.preview(String authId) {
    return OAuthAuthorizationDetails(
      authorizationId: authId,
      clientName: 'Quest Developer Studio (MCP)',
      clientLogoUrl: null,
      redirectUri: 'http://localhost:3000/callback',
      scopes: ['openid', 'profile', 'email', 'offline_access'],
    );
  }
}

class OAuthServerService {
  final Dio _dio;
  final SupabaseClient _supabase;
  final String _baseUrl;
  final String _anonKey;

  OAuthServerService({Dio? dio, SupabaseClient? supabase})
    : _dio = dio ?? Dio(),
      _supabase = supabase ?? Supabase.instance.client,
      _baseUrl =
          dotenv.env['SUPABASE_URL'] ??
          'https://ipvsbunseucoheycxpeg.supabase.co',
      _anonKey =
          dotenv.env['SUPABASE_ANON_KEY'] ??
          'sb_publishable_HG9KaCul4NDePDRYEruZfg_OUaQ42Y7';

  Map<String, String> _buildHeaders() {
    final session = _supabase.auth.currentSession;
    final token = session?.accessToken;

    return {
      'apikey': _anonKey,
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Fetches client and requested scope details for a given authorization ID.
  Future<OAuthAuthorizationDetails> getAuthorizationDetails(
    String authorizationId,
  ) async {
    if (authorizationId.isEmpty || authorizationId == 'preview_test') {
      return OAuthAuthorizationDetails.preview(authorizationId);
    }

    try {
      final response = await _dio.get(
        '$_baseUrl/auth/v1/oauth/authorizations/$authorizationId',
        options: Options(headers: _buildHeaders()),
      );

      final data = response.data as Map<String, dynamic>;
      return OAuthAuthorizationDetails.fromJson(authorizationId, data);
    } on DioException catch (e) {
      // Fallback for preview or offline testing
      if (authorizationId.startsWith('test_') ||
          authorizationId.startsWith('preview_')) {
        return OAuthAuthorizationDetails.preview(authorizationId);
      }
      final msg = e.response?.data is Map
          ? (e.response?.data['msg'] ??
                e.response?.data['message'] ??
                e.message)
          : e.message;
      throw Exception('Failed to load authorization details: $msg');
    } catch (e) {
      throw Exception('Failed to retrieve OAuth authorization: $e');
    }
  }

  /// Approves the OAuth authorization and returns the client callback redirect URL.
  Future<String> approveAuthorization(String authorizationId) async {
    if (authorizationId.isEmpty ||
        authorizationId.startsWith('preview_') ||
        authorizationId.startsWith('test_')) {
      return 'http://localhost:3000/callback?code=mock_oauth_code_success&state=preview';
    }

    try {
      final response = await _dio.post(
        '$_baseUrl/auth/v1/oauth/authorizations/$authorizationId/consent',
        data: {'action': 'approve'},
        options: Options(headers: _buildHeaders()),
      );

      final data = response.data as Map<String, dynamic>;
      final redirectUrl = data['redirect_url'] as String?;
      if (redirectUrl == null || redirectUrl.isEmpty) {
        throw Exception('Server did not return a redirect URL');
      }
      return redirectUrl;
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data['msg'] ??
                e.response?.data['message'] ??
                e.message)
          : e.message;
      throw Exception('Failed to approve authorization: $msg');
    }
  }

  /// Denies the OAuth authorization and returns the client callback redirect URL with error.
  Future<String> denyAuthorization(String authorizationId) async {
    if (authorizationId.isEmpty ||
        authorizationId.startsWith('preview_') ||
        authorizationId.startsWith('test_')) {
      return 'http://localhost:3000/callback?error=access_denied&error_description=User+denied+authorization';
    }

    try {
      final response = await _dio.post(
        '$_baseUrl/auth/v1/oauth/authorizations/$authorizationId/consent',
        data: {'action': 'deny'},
        options: Options(headers: _buildHeaders()),
      );

      final data = response.data as Map<String, dynamic>;
      final redirectUrl = data['redirect_url'] as String?;
      if (redirectUrl == null || redirectUrl.isEmpty) {
        throw Exception('Server did not return a redirect URL');
      }
      return redirectUrl;
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data['msg'] ??
                e.response?.data['message'] ??
                e.message)
          : e.message;
      throw Exception('Failed to deny authorization: $msg');
    }
  }
}

final oauthServerServiceProvider = Provider<OAuthServerService>((ref) {
  return OAuthServerService();
});
