import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  User? get currentUser;
  Future<void> signOut();
  Future<User?> signInWithEmail(String email, String password);
  Future<User?> signUpWithEmail(String email, String password, String name);
}

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;

  SupabaseAuthRepository(this._client);

  @override
  Stream<User?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((data) => data.session?.user);
  }

  @override
  User? get currentUser => _client.auth.currentSession?.user;

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<User?> signInWithEmail(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response.user;
  }

  @override
  Future<User?> signUpWithEmail(String email, String password, String name) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name},
    );
    return response.user;
  }
}
