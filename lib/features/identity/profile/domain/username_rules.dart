/// Local (client-side) username rules. These only give instant feedback —
/// the database (unique index + CHECK constraint) is the real authority.
class UsernameRules {
  static const int minLength = 3;
  static const int maxLength = 30;
  static final RegExp _pattern = RegExp(r'^[a-z0-9_]+$');

  /// Canonical stored form (lower-case, trimmed, no leading '@').
  static String normalize(String input) {
    var v = input.trim().toLowerCase();
    if (v.startsWith('@')) v = v.substring(1);
    return v;
  }

  /// Returns a user-facing error, or null when the format is valid.
  static String? validate(String input) {
    final v = normalize(input);
    if (v.isEmpty) return 'Choose a username';
    if (v.length < minLength) return 'At least $minLength characters';
    if (v.length > maxLength) return 'At most $maxLength characters';
    if (!_pattern.hasMatch(v)) {
      return 'Only letters, numbers and underscores';
    }
    return null;
  }
}
