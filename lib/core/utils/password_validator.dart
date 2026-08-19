/// Reusable password-strength rules shared across screens (registration,
/// change password, reset password, etc.).
///
/// Centralizes the exact requirements so logic is never duplicated and the
/// requirements stay consistent app-wide. Consumed by the UI to render a live
/// requirements checklist and to gate form submission.
class PasswordValidator {
  PasswordValidator._();

  /// Minimum number of characters.
  static const int minLength = 8;

  /// Whether the password meets the minimum length requirement.
  static bool hasMinLength(String value) => value.length >= minLength;

  /// Whether the password contains at least one uppercase letter.
  static bool hasUppercase(String value) => value.contains(RegExp(r'[A-Z]'));

  /// Whether the password contains at least one lowercase letter.
  static bool hasLowercase(String value) => value.contains(RegExp(r'[a-z]'));

  /// Whether the password contains at least one digit.
  static bool hasNumber(String value) => value.contains(RegExp(r'[0-9]'));

  /// Whether the password contains at least one special character.
  static bool hasSpecialChar(String value) =>
      value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  /// Whether every password requirement is satisfied.
  static bool isStrong(String value) =>
      hasMinLength(value) &&
      hasUppercase(value) &&
      hasLowercase(value) &&
      hasNumber(value) &&
      hasSpecialChar(value);

  /// A canonical, ordered list of `(label, isMet)` pairs for rendering a
  /// real-time requirements checklist.
  static List<PasswordRequirement> requirements(String value) => [
    PasswordRequirement('$minLength+ characters', hasMinLength(value)),
    PasswordRequirement('1 uppercase letter', hasUppercase(value)),
    PasswordRequirement('1 lowercase letter', hasLowercase(value)),
    PasswordRequirement('1 number', hasNumber(value)),
    PasswordRequirement('1 special char', hasSpecialChar(value)),
  ];
}

/// A single password requirement with its current satisfaction state.
class PasswordRequirement {
  final String label;
  final bool isMet;

  const PasswordRequirement(this.label, this.isMet);
}
