enum AppThemeType { modernTeal, saasBlue, premiumMinimal }

extension AppThemeTypeX on AppThemeType {
  String get storageValue => name;

  static AppThemeType fromStorage(String? value) {
    return AppThemeType.values.firstWhere(
      (theme) => theme.name == value,
      orElse: () => AppThemeType.saasBlue,
    );
  }
}
