import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:quest/core/env/env.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Env Security & Configuration Test', () {
    test('Env.init() loads clean client environment without server secrets', () async {
      await Env.init();

      // Ensure no server-side secrets exist in memory after init
      expect(
        dotenv.env['SUPABASE_SERVICE_ROLE_KEY'],
        isNull,
        reason: 'SUPABASE_SERVICE_ROLE_KEY must not exist in client environment',
      );
      expect(
        dotenv.env['MUX_TOKEN_SECRET'],
        isNull,
        reason: 'MUX_TOKEN_SECRET must not exist in client environment',
      );
      expect(
        dotenv.env['CLOUDINARY_API_SECRET'],
        isNull,
        reason: 'CLOUDINARY_API_SECRET must not exist in client environment',
      );
      expect(
        dotenv.env['IMAGEKIT_PRIVATE_KEY'],
        isNull,
        reason: 'IMAGEKIT_PRIVATE_KEY must not exist in client environment',
      );

      // Verify public configuration is populated
      expect(Env.supabaseUrl, isNotEmpty);
      expect(Env.supabaseAnonKey, isNotEmpty);
    });

    test('Env.sanitizeEnvironment() strips forbidden server secrets from memory', () {
      // Inject forbidden secrets into dotenv
      dotenv.testLoad(
        mergeWith: {
          'SUPABASE_SERVICE_ROLE_KEY': 'sb_secret_prohibited',
          'MUX_TOKEN_SECRET': 'mux_secret_prohibited',
          'CLOUDINARY_API_SECRET': 'cloudinary_secret_prohibited',
          'IMAGEKIT_PRIVATE_KEY': 'imagekit_private_prohibited',
          'SUPABASE_URL': 'https://custom-test.supabase.co',
        },
      );

      expect(dotenv.env['SUPABASE_SERVICE_ROLE_KEY'], isNotNull);
      expect(dotenv.env['MUX_TOKEN_SECRET'], isNotNull);
      expect(dotenv.env['CLOUDINARY_API_SECRET'], isNotNull);
      expect(dotenv.env['IMAGEKIT_PRIVATE_KEY'], isNotNull);

      // Trigger sanitization
      Env.sanitizeEnvironment();

      expect(dotenv.env['SUPABASE_SERVICE_ROLE_KEY'], isNull);
      expect(dotenv.env['MUX_TOKEN_SECRET'], isNull);
      expect(dotenv.env['CLOUDINARY_API_SECRET'], isNull);
      expect(dotenv.env['IMAGEKIT_PRIVATE_KEY'], isNull);
      expect(Env.supabaseUrl, equals('https://custom-test.supabase.co'));
    });
  });
}
