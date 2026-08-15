/// Validation utilities for ReserveHub.
/// Pure functions — no Flutter dependencies.
class ValidationUtils {
  ValidationUtils._();

  // ─── Email ─────────────────────────────────────────────────────────────────

  static bool isValidEmail(String value) {
    return RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(value.trim());
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required.';
    if (!isValidEmail(value)) return 'Enter a valid email address.';
    return null;
  }

  // ─── Password ──────────────────────────────────────────────────────────────

  static bool isValidPassword(String value) => value.length >= 8;

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (value.length < 8) return 'Password must be at least 8 characters.';
    return null;
  }

  static String? validateConfirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Please confirm your password.';
    if (value != original) return 'Passwords do not match.';
    return null;
  }

  // ─── Phone ─────────────────────────────────────────────────────────────────

  static bool isValidPhone(String value) {
    return RegExp(r'^\+?[0-9\s\-().]{7,20}$').hasMatch(value.trim());
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required.';
    }
    if (!isValidPhone(value)) return 'Enter a valid phone number.';
    return null;
  }

  // ─── Required ──────────────────────────────────────────────────────────────

  static String? validateRequired(
    String? value, {
    String fieldName = 'This field',
  }) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required.';
    return null;
  }

  // ─── Name ──────────────────────────────────────────────────────────────────

  static String? validateName(String? value, {String fieldName = 'Name'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required.';
    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters.';
    }
    if (value.trim().length > 100) {
      return '$fieldName must be under 100 characters.';
    }
    return null;
  }

  // ─── URL ───────────────────────────────────────────────────────────────────

  static bool isValidUrl(String value) {
    return Uri.tryParse(value)?.hasAbsolutePath ?? false;
  }

  static String? validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    if (!isValidUrl(value)) return 'Enter a valid URL.';
    return null;
  }

  // ─── Numeric ───────────────────────────────────────────────────────────────

  static String? validatePositiveNumber(
    String? value, {
    String fieldName = 'Value',
  }) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required.';
    final n = double.tryParse(value.trim());
    if (n == null) return '$fieldName must be a number.';
    if (n <= 0) return '$fieldName must be greater than zero.';
    return null;
  }

  static String? validateNonNegativeNumber(
    String? value, {
    String fieldName = 'Value',
  }) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required.';
    final n = double.tryParse(value.trim());
    if (n == null) return '$fieldName must be a number.';
    if (n < 0) return '$fieldName cannot be negative.';
    return null;
  }
}
