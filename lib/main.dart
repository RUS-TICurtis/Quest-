import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Initialize Supabase here once credentials are configured
  // await Supabase.initialize(url: '...', anonKey: '...');

  runApp(
    const ProviderScope(
      child: QuestApp(),
    ),
  );
}
