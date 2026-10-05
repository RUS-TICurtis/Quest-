import 'dart:math';
import 'package:flutter/services.dart';
import 'package:quest/core/env/env.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  User? get currentUser;
  Future<void> signOut();
  Future<User?> signInWithEmail(String email, String password);
  Future<AuthResponse> signUpWithEmail(
    String email,
    String password,
    String name,
  );
  Future<AuthResponse?> signInWithGoogleNative();
  Future<AuthResponse> signInAnonymously();

  /// Whether a Quest profile exists for [userId] with onboarding finished.
  Future<bool> hasCompletedProfile(String userId);
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
    try {
      // Clear the cached Google account so the chooser is shown next time.
      await GoogleSignIn().signOut();
    } catch (_) {
      // Not signed in with Google on this device — nothing to clear.
    }
  }

  @override
  Future<bool> hasCompletedProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select('onboarding_completed')
        .eq('id', userId)
        .maybeSingle();
    return row != null && row['onboarding_completed'] == true;
  }

  @override
  Future<User?> signInWithEmail(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response.user;
  }

  Future<String> _generateUniqueUsername(String name) async {
    String base = name
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');

    if (base.isEmpty) {
      base = 'user${DateTime.now().millisecondsSinceEpoch}';
    }

    final random = Random();
    final suggestions = [
      base,
      "$base${random.nextInt(99)}",
      "$base${random.nextInt(999)}",
      "${base}_${random.nextInt(9)}",
      "$base${DateTime.now().millisecond}",
    ];

    for (String suggestion in suggestions) {
      if (suggestion.trim().isEmpty) continue;

      try {
        final response = await _client
            .from('profiles')
            .select('username')
            .eq('username', suggestion)
            .maybeSingle();
        if (response == null) {
          return suggestion;
        }
      } catch (e) {
        if (e.toString().contains('No URI/host specified')) {
          rethrow;
        }
      }
    }

    return "$base${DateTime.now().millisecondsSinceEpoch}";
  }

  @override
  Future<AuthResponse> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    final generatedUsername = await _generateUniqueUsername(name);
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'full_name': name, 'display_name': name, 'username': generatedUsername},
    );
    return response;
  }

  @override
  Future<AuthResponse?> signInWithGoogleNative() async {
    final webClientId = Env.googleWebClientId;
    final iosClientId = Env.googleIosClientId;

    if (webClientId == null || webClientId.trim().isEmpty) {
      throw const AuthException(
        'Google Web Client ID is not configured. Please set GOOGLE_WEB_CLIENT_ID in your .env file.',
      );
    }

    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: iosClientId,
      serverClientId: webClientId,
      scopes: ['email', 'profile', 'openid'],
    );

    GoogleSignInAccount? googleUser;
    try {
      googleUser = await googleSignIn.signIn();
    } on PlatformException catch (e) {
      final errString = e.toString();
      if (errString.contains('10') || errString.contains('DEVELOPER_ERROR')) {
        throw const AuthException(
          'Google Sign-In configuration error (Developer Error 10):\n'
          'The SHA-1 fingerprint is not registered in Google Cloud Console under an Android OAuth Client ID for package "com.quest.quest".',
        );
      }
      throw AuthException(
        'Google Sign-In failed: ${e.message ?? e.toString()}',
      );
    }

    if (googleUser == null) {
      // User dismissed or cancelled the modal
      return null;
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw const AuthException(
        'No Google ID token was returned by the sign-in modal.',
      );
    }

    final response = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    return response;
  }

  @override
  Future<AuthResponse> signInAnonymously() async {
    return await _client.auth.signInAnonymously();
  }
}
