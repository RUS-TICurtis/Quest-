import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/env/env.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'core/storage/local_storage_service.dart';
import 'core/storage/local_database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Env.init();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
  );

  final sharedPreferences = await SharedPreferences.getInstance();

  final localDatabaseService = LocalDatabaseService();
  await localDatabaseService.init();

  runApp(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(
          LocalStorageService(sharedPreferences),
        ),
        localDatabaseProvider.overrideWithValue(localDatabaseService),
      ],
      child: QuestApp(),
    ),
  );
}
