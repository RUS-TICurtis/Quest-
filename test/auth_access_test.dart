import 'package:flutter_test/flutter_test.dart';
import 'package:quest/features/identity/auth/data/auth_provider.dart';
import 'package:quest/features/identity/profile/domain/username_rules.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

User _user({required bool anonymous}) => User(
  id: 'u1',
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  createdAt: DateTime.now().toIso8601String(),
  isAnonymous: anonymous,
);

void main() {
  group('AccessLevel', () {
    test('no user -> unauthenticated', () {
      final s = AuthState(isLoading: false);
      expect(s.accessLevel, AccessLevel.unauthenticated);
      expect(s.isAuthenticated, isFalse);
    });

    test('anonymous session -> guest, not a member', () {
      final s = AuthState(user: _user(anonymous: true), isLoading: false);
      expect(s.accessLevel, AccessLevel.guest);
      expect(s.isGuest, isTrue);
    });

    test('real session -> member', () {
      final s = AuthState(user: _user(anonymous: false), isLoading: false);
      expect(s.accessLevel, AccessLevel.member);
    });

    test('clearUser (logout / revoked session) -> unauthenticated', () {
      final s = AuthState(user: _user(anonymous: false), isLoading: false)
          .copyWith(clearUser: true);
      expect(s.accessLevel, AccessLevel.unauthenticated);
    });
  });

  group('UsernameRules', () {
    test('normalizes case, whitespace and leading @', () {
      expect(UsernameRules.normalize('  @Quest_Fan '), 'quest_fan');
    });

    test('accepts valid usernames', () {
      expect(UsernameRules.validate('abc'), isNull);
      expect(UsernameRules.validate('Quest_99'), isNull);
    });

    test('rejects empty, short, long and illegal characters', () {
      expect(UsernameRules.validate(''), isNotNull);
      expect(UsernameRules.validate('ab'), isNotNull);
      expect(UsernameRules.validate('a' * 31), isNotNull);
      expect(UsernameRules.validate('no spaces'), isNotNull);
      expect(UsernameRules.validate('emoji😀'), isNotNull);
      expect(UsernameRules.validate('dash-name'), isNotNull);
    });
  });
}
