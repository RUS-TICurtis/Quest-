import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Listen to Supabase auth changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      state = state.copyWith(user: session?.user, isLoading: false);
    });

    // Initial state based on current session
    final initialSession = Supabase.instance.client.auth.currentSession;
    return AuthState(user: initialSession?.user, isLoading: false);
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }
  
  // For the sake of mock UI testing before real backend is connected:
  void mockSignIn() {
    // This is a temporary hack for development to bypass auth guards
    // without actually connecting to Supabase yet.
    // In a real app, you'd never do this.
    state = state.copyWith(
      user: const User(
        id: 'mock-user-id', 
        appMetadata: {}, 
        userMetadata: {}, 
        aud: 'authenticated', 
        createdAt: ''
      ),
      isLoading: false
    );
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
