/// Kebijakan password, mengikuti backend (change-password) dan web:
/// minimal 8 karakter, huruf besar + kecil, angka, dan karakter spesial.
class PasswordPolicy {
  PasswordPolicy._();

  static const int minLength = 8;

  static bool hasMinLength(String p) => p.length >= minLength;
  static bool hasUpperLower(String p) =>
      p.contains(RegExp(r'[a-z]')) && p.contains(RegExp(r'[A-Z]'));
  static bool hasNumber(String p) => p.contains(RegExp(r'[0-9]'));
  static bool hasSpecial(String p) => p.contains(RegExp(r'[^A-Za-z0-9]'));

  static bool isStrong(String p) =>
      hasMinLength(p) && hasUpperLower(p) && hasNumber(p) && hasSpecial(p);

  /// Pesan error pertama menurut urutan validasi server, atau null jika lolos.
  static String? validate(String p) {
    if (!hasMinLength(p)) {
      return 'The password must be at least $minLength characters long.';
    }
    if (!hasUpperLower(p)) {
      return 'The password must contain both uppercase and lowercase letters.';
    }
    if (!hasNumber(p)) return 'The password must contain a number.';
    if (!hasSpecial(p)) return 'The password must contain a special character.';
    return null;
  }
}