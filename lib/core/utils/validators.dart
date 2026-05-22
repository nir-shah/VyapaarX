class Validators {
  const Validators._();

  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static final RegExp _gstinPattern = RegExp(
    r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$',
  );

  static String? requiredText(
    String? value, {
    String fieldName = 'This field',
  }) {
    if ((value ?? '').trim().isEmpty) {
      return '$fieldName is required.';
    }
    return null;
  }

  static String? email(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Email is required.';
    if (!_emailPattern.hasMatch(email)) return 'Enter a valid email address.';
    return null;
  }

  static String? optionalEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return null;
    if (!_emailPattern.hasMatch(email)) return 'Enter a valid email address.';
    return null;
  }

  static String? indianPhone(String? value, {bool optional = false}) {
    final raw = (value ?? '').trim();
    if (optional && raw.isEmpty) return null;

    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 10 &&
        !(digits.length == 12 && digits.startsWith('91'))) {
      return 'Enter a valid 10 digit mobile number.';
    }
    return null;
  }

  static String? gstin(String? value) {
    final gstin = (value ?? '').trim().toUpperCase();
    if (gstin.isEmpty) return null;
    if (!_gstinPattern.hasMatch(gstin)) {
      return 'Enter a valid 15 character GSTIN.';
    }
    return null;
  }

  static String? optionalGstin(String? value) {
    final gstin = (value ?? '').trim().toUpperCase();
    if (gstin.isEmpty) return null;
    if (!_gstinPattern.hasMatch(gstin)) {
      return 'Enter a valid 15 character GSTIN.';
    }
    return null;
  }

  static String? pinCode(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 6) return 'Enter a valid 6 digit pin code.';
    return null;
  }

  static String? amount(String? value, {bool optional = false}) {
    final raw = (value ?? '').trim();
    if (optional && raw.isEmpty) return null;
    final amount = double.tryParse(raw);
    if (amount == null || amount < 0) {
      return 'Enter a valid amount.';
    }
    return null;
  }

  static String? wholeNumber(String? value, {String fieldName = 'Value'}) {
    final raw = (value ?? '').trim();
    final number = int.tryParse(raw);
    if (number == null || number < 0) {
      return '$fieldName must be zero or more.';
    }
    return null;
  }

  static String? gstRate(String? value) {
    final raw = (value ?? '').trim();
    final rate = double.tryParse(raw);
    if (rate == null || rate < 0 || rate > 28) {
      return 'Enter a GST rate between 0 and 28.';
    }
    return null;
  }

  static String? hsnCode(String? value) {
    final code = (value ?? '').trim();
    if (code.isEmpty) return 'HSN code is required.';
    if (!RegExp(r'^[0-9]{4,8}$').hasMatch(code)) {
      return 'Enter a valid 4 to 8 digit HSN code.';
    }
    return null;
  }
}
