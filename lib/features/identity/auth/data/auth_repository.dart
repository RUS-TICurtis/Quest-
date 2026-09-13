import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  User? get currentUser;
  Future<void> signOut();
  Future<User?> signInWithEmail(String email, String password);
  Future<AuthResponse> signUpWithEmail(String email, String password, String name);
  Future<AuthResponse?> signInWithGoogleNative();
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
  Future<AuthResponse> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'full_name': name,
        'display_name': name,
      },
    );
    return response;
  }

  @override
  Future<AuthResponse?> signInWithGoogleNative() async {
    final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
    final iosClientId = dotenv.env['GOOGLE_IOS_CLIENT_ID'];

    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: iosClientId,
      serverClientId: webClientId,
      scopes: ['email', 'profile', 'openid'],
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      // User dismissed or cancelled the modal
      return null;
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw const AuthException('No Google ID token was returned by the sign-in modal.');
    }

    final response = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    return response;
  }
}
