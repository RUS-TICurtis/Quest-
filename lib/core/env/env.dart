import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static Future<void> init() async {
    await dotenv.load(fileName: '.env');
  }

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? 'https://your-project-ref.supabase.co';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? 'your-supabase-anon-key';
}
