import '../constants/app_constants.dart';

class AppFormatters {
  const AppFormatters._();

  static String currency(num value) {
    final rounded = value.round();
    final raw = rounded.abs().toString();
    final buffer = StringBuffer();

    for (var index = 0; index < raw.length; index++) {
      final remaining = raw.length - index;
      buffer.write(raw[index]);
      if (remaining > 1 && remaining % 2 == 0 && index != raw.length - 1) {
        buffer.write(',');
      }
    }

    final sign = rounded < 0 ? '-' : '';
    return '$sign${AppConstants.rupeeSymbol}${buffer.toString()}';
  }

  static String phoneForDisplay(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('91') && digits.length == 12) {
      return '+91 ${digits.substring(2, 7)} ${digits.substring(7)}';
    }
    if (digits.length == 10) {
      return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
    }
    return phone;
  }

  static String normalizeIndianPhone(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('91') && digits.length == 12) return '+$digits';
    return '+91$digits';
  }

  static String? optionalIndianPhone(String value) {
    if (value.trim().isEmpty) return null;
    return normalizeIndianPhone(value);
  }
}
