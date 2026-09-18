import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quest/features/identity/auth/data/auth_repository.dart';

class AuthState {
  final User? user;
  final bool isLoading;

  AuthState({this.user, this.isLoading = true});

  bool get isAuthenticated => user != null;

  AuthState copyWith({User? user, bool? isLoading}) {
    return AuthState(
      user: user ?? this.user,
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

    // Listen to repository auth changes — cancel subscription on dispose
    final StreamSubscription<User?> sub = _repository.authStateChanges.listen((
      user,
    ) {
      state = state.copyWith(user: user, isLoading: false);
    });
    ref.onDispose(sub.cancel);

    // Initial state
    final initialUser = _repository.currentUser;
    return AuthState(user: initialUser, isLoading: false);
  }

  Future<void> signOut() async {
    try {
      await _repository.signOut();
    } catch (e) {
      // Ignore Supabase network errors on sign out
    } finally {
      // Guarantee local state reflects sign out so router redirects
      state = state.copyWith(user: null, isLoading: false);
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

  Future<AuthResponse?> signInWithGoogleNative() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _repository.signInWithGoogleNative();
      if (response != null && response.user != null) {
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
