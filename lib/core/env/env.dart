import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Secure environment configuration reader.
///
/// Priority:
/// 1. Compile-time `--dart-define` (`String.fromEnvironment`)
/// 2. `.env` asset file (sanitized, public keys only)
/// 3. Safe fallback defaults
///
/// NOTE: Privileged secrets (`SUPABASE_SERVICE_ROLE_KEY`, `MUX_TOKEN_SECRET`,
/// `CLOUDINARY_API_SECRET`, `IMAGEKIT_PRIVATE_KEY`) MUST NEVER be included in
/// the client. Any such keys found are stripped on initialization.
class Env {
  static const List<String> _forbiddenSecretKeys = [
    'SUPABASE_SERVICE_ROLE_KEY',
    'MUX_TOKEN_SECRET',
    'CLOUDINARY_API_SECRET',
    'IMAGEKIT_PRIVATE_KEY',
  ];

  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
      sanitizeEnvironment();
    } catch (e) {
      debugPrint('[Env] Notice: .env file not loaded ($e); relying on environment defines.');
    }
  }

  /// Strips any accidental server secrets from memory to prevent client exfiltration.
  static void sanitizeEnvironment() {
    for (final secret in _forbiddenSecretKeys) {
      if (dotenv.env.containsKey(secret)) {
        debugPrint(
          '[SECURITY ALERT] Prohibited server secret "$secret" was detected in client .env! '
          'Purging from memory immediately. Move this secret to Supabase Edge Functions.',
        );
        dotenv.env.remove(secret);
      }
    }
  }

  // ── Public Client Configuration ──────────────────────────────────────────

  static String get supabaseUrl =>
      const String.fromEnvironment('SUPABASE_URL', defaultValue: '').isNotEmpty
          ? const String.fromEnvironment('SUPABASE_URL')
          : (dotenv.env['SUPABASE_URL'] ??
              'https://ipvsbunseucoheycxpeg.supabase.co');

  static String get supabaseAnonKey =>
      const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '').isNotEmpty
          ? const String.fromEnvironment('SUPABASE_ANON_KEY')
          : (dotenv.env['SUPABASE_ANON_KEY'] ??
              'sb_publishable_HG9KaCul4NDePDRYEruZfg_OUaQ42Y7');

  static String? get googleWebClientId =>
      const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '').isNotEmpty
          ? const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID')
          : dotenv.env['GOOGLE_WEB_CLIENT_ID'];

  static String? get googleIosClientId =>
      const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID', defaultValue: '').isNotEmpty
          ? const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID')
          : dotenv.env['GOOGLE_IOS_CLIENT_ID'];

  static String get cloudinaryCloudName =>
      const String.fromEnvironment('CLOUDINARY_CLOUD_NAME', defaultValue: '').isNotEmpty
          ? const String.fromEnvironment('CLOUDINARY_CLOUD_NAME')
          : (dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? 'wmjg4pug');

  static String? get imageKitPublicKey =>
      const String.fromEnvironment('IMAGEKIT_PUBLIC_KEY', defaultValue: '').isNotEmpty
          ? const String.fromEnvironment('IMAGEKIT_PUBLIC_KEY')
          : dotenv.env['IMAGEKIT_PUBLIC_KEY'];
}
