// Non-network application constants.
// All API endpoint paths live exclusively in ApiConstants — do not add
// endpoint strings here to avoid silent divergence between the two files.
class AppConstants {
  AppConstants._();

  static const String appName = 'Mama Health Admin';
  static const String appVersion = '1.0.0';

  // SharedPreferences / secure-storage keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
}
