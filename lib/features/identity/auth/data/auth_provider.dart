import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quest/features/identity/auth/data/auth_repository.dart';
import 'package:quest/core/storage/local_storage_service.dart';
import 'package:quest/features/identity/profile/data/user_provider.dart';

/// Coarse access level derived from the session. Finer roles (organizer,
/// admin…) live in `profiles.role` and are enforced server-side.
enum AccessLevel { unauthenticated, guest, member }

/// What the user intended when tapping "Continue with Google".
enum GoogleIntent { signIn, signUp }

enum GoogleAuthOutcome {
  /// User dismissed the Google chooser.
  cancelled,

  /// Existing Quest account signed in.
  signedIn,

  /// A brand-new Quest account was created (router will send to onboarding).
  createdAccount,

  /// Sign-in intent but no Quest account exists for this Google identity.
  noAccount,

  /// Sign-up intent but a Quest account already exists.
  accountExists,
}

class AuthState {
  final User? user;
  final bool isLoading;

  AuthState({this.user, this.isLoading = true});

  bool get isAuthenticated => user != null;
  bool get isGuest => user?.isAnonymous ?? false;

  AccessLevel get accessLevel {
    if (user == null) return AccessLevel.unauthenticated;
    return isGuest ? AccessLevel.guest : AccessLevel.member;
  }

  AuthState copyWith({User? user, bool? isLoading, bool clearUser = false}) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Global provider for the repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(Supabase.instance.client);
});

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);

    // Listen to repository auth changes — cancel subscription on dispose.
    // The stream also carries token refreshes and revoked/expired sessions
    // (user == null), which flow straight into the router redirect.
    final StreamSubscription<User?> sub = _repository.authStateChanges.listen((
      user,
    ) {
      state = user == null
          ? state.copyWith(clearUser: true, isLoading: false)
          : state.copyWith(user: user, isLoading: false);
    });
    ref.onDispose(sub.cancel);

    // Supabase restores the persisted session synchronously during
    // Supabase.initialize(), so currentUser is authoritative at this point.
    return AuthState(user: _repository.currentUser, isLoading: false);
  }

  Future<void> signOut() async {
    try {
      await _repository.signOut();
    } catch (_) {
      // Network failure on remote revoke: local session is still cleared below.
    } finally {
      // Never leave one account's cached profile for the next account.
      await ref.read(localStorageServiceProvider).clearProfile();
      ref.invalidate(userProvider);
      state = state.copyWith(clearUser: true, isLoading: false);
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _repository.signInWithEmail(email, password);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<AuthResponse> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _repository.signUpWithEmail(email, password, name);
      if (response.session != null) {
        state = state.copyWith(user: response.user, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
      return response;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  /// Google authentication with explicit product intent.
  ///
  /// The OAuth handshake is shared, but a failed *sign-in* must never silently
  /// become account creation, and a *sign-up* must never duplicate an account.
  ///
  /// Limitation: Supabase creates the `auth.users` row during the handshake, so
  /// a rejected sign-in leaves an orphan auth identity (no profile) until a
  /// server-side cleanup exists. It is signed out immediately.
  Future<GoogleAuthOutcome> continueWithGoogle(GoogleIntent intent) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _repository.signInWithGoogleNative();
      final user = response?.user;
      if (user == null) {
        state = state.copyWith(isLoading: false);
        return GoogleAuthOutcome.cancelled;
      }

      final createdAt = DateTime.tryParse(user.createdAt)?.toUtc();
      final isBrandNew =
          createdAt != null &&
          DateTime.now().toUtc().difference(createdAt).inSeconds.abs() < 60;
      final hasProfile = await _repository.hasCompletedProfile(user.id);

      if (intent == GoogleIntent.signIn && isBrandNew && !hasProfile) {
        await signOut();
        return GoogleAuthOutcome.noAccount;
      }
      if (intent == GoogleIntent.signUp && !isBrandNew && hasProfile) {
        await signOut();
        return GoogleAuthOutcome.accountExists;
      }

      state = state.copyWith(user: user, isLoading: false);
      return isBrandNew
          ? GoogleAuthOutcome.createdAccount
          : GoogleAuthOutcome.signedIn;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<AuthResponse> signInAnonymously() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _repository.signInAnonymously();
      if (response.user != null) {
        state = state.copyWith(user: response.user, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
      return response;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
