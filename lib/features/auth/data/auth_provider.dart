import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_repository.dart';

class AuthState {
  final User? user;
  final bool isLoading;

  const AuthState({this.user, this.isLoading = true});

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
    
    // Listen to repository auth changes
    _repository.authStateChanges.listen((user) {
      state = state.copyWith(user: user, isLoading: false);
    });

    // Initial state
    final initialUser = _repository.currentUser;
    return AuthState(user: initialUser, isLoading: false);
  }

  Future<void> signOut() async {
    await _repository.signOut();
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

  Future<void> signUpWithEmail(String email, String password, String name) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _repository.signUpWithEmail(email, password, name);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
