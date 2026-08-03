import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String accessTokenKey = 'auth_access_token';
  static const String refreshTokenKey = 'auth_refresh_token';
  static const String isAuthenticatedKey = 'auth_is_authenticated';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    debugPrint('[Storage] SharedPreferences initialized.');
  }

  SharedPreferences get _instance {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError(
        'LocalStorageService not initialized. Call LocalStorageService.init() in main().',
      );
    }
    return prefs;
  }

  Future<void> setString(String key, String value) async {
    await _instance.setString(key, value);
    debugPrint('[Storage] setString key=$key');
  }

  Future<String?> getString(String key) async {
    final value = _instance.getString(key);
    debugPrint('[Storage] getString key=$key found=${value != null}');
    return value;
  }

  String? getStringSync(String key) {
    final value = _instance.getString(key);
    debugPrint('[Storage] getStringSync key=$key found=${value != null}');
    return value;
  }

  Future<void> setBool(String key, bool value) async {
    await _instance.setBool(key, value);
    debugPrint('[Storage] setBool key=$key value=$value');
  }

  Future<bool?> getBool(String key) async {
    final value = _instance.getBool(key);
    debugPrint('[Storage] getBool key=$key value=$value');
    return value;
  }

  bool getBoolSync(String key) {
    final value = _instance.getBool(key) ?? false;
    debugPrint('[Storage] getBoolSync key=$key value=$value');
    return value;
  }

  Future<void> remove(String key) async {
    await _instance.remove(key);
    debugPrint('[Storage] remove key=$key');
  }

  Future<void> clear() async {
    await _instance.clear();
    debugPrint('[Storage] clear all keys');
  }

  Future<void> saveAuthTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _instance.setString(accessTokenKey, accessToken);
    await _instance.setString(refreshTokenKey, refreshToken);
    await _instance.setBool(isAuthenticatedKey, true);
    debugPrint(
      '[Storage] saveAuthTokens success access_len=${accessToken.length} refresh_len=${refreshToken.length}',
    );
  }

  Future<String?> getAccessToken() => getString(accessTokenKey);

  Future<String?> getRefreshToken() => getString(refreshTokenKey);

  String getAccessTokenSync() => _instance.getString(accessTokenKey) ?? '';

  Future<bool> isAuthenticated() async {
    final hasToken = (_instance.getString(accessTokenKey) ?? '').isNotEmpty;
    final flag = _instance.getBool(isAuthenticatedKey) ?? false;
    final value = hasToken && flag;
    debugPrint(
      '[Storage] isAuthenticated value=$value hasToken=$hasToken flag=$flag',
    );
    return value;
  }

  bool isAuthenticatedSync() {
    final hasToken = (_instance.getString(accessTokenKey) ?? '').isNotEmpty;
    final flag = _instance.getBool(isAuthenticatedKey) ?? false;
    final value = hasToken && flag;
    debugPrint(
      '[Storage] isAuthenticatedSync value=$value hasToken=$hasToken flag=$flag',
    );
    return value;
  }

  Future<void> clearAuth() async {
    await _instance.remove(accessTokenKey);
    await _instance.remove(refreshTokenKey);
    await _instance.setBool(isAuthenticatedKey, false);
    debugPrint('[Storage] clearAuth completed.');
  }
}
