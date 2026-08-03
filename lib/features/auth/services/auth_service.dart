import 'package:admin/core/services/local_storage_service.dart';
import 'package:admin/features/auth/models/login_request.dart';
import 'package:admin/features/auth/models/login_response.dart';
import 'package:admin/features/auth/repositories/auth_repository.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final AuthRepository _authRepository;
  final LocalStorageService _storageService;

  String? _passwordResetEmail;
  String? _passwordResetToken;

  AuthService(this._authRepository, this._storageService);

  String? get passwordResetEmail => _passwordResetEmail;

  String? get passwordResetToken => _passwordResetToken;

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    debugPrint('[AuthService] Login flow started for ${_maskEmail(email)}');
    final response = await _authRepository.login(
      LoginRequest(email: email, password: password),
    );

    await _storageService.saveAuthTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    debugPrint('[AuthService] Login success. Token persistence completed.');
    return response;
  }

  Future<void> requestPasswordResetCode(String email) async {
    debugPrint(
      '[AuthService] Password reset request started for ${_maskEmail(email)}',
    );
    await _authRepository.forgotPassword(email);
    _passwordResetEmail = email;
    debugPrint(
      '[AuthService] Password reset request succeeded. Email cached for OTP flow.',
    );
  }

  Future<void> verifyPasswordResetOtp({
    required String email,
    required String otpCode,
  }) async {
    debugPrint(
      '[AuthService] OTP verification started for ${_maskEmail(email)}',
    );
    final resetToken = await _authRepository.verifyPasswordOtp(
      email: email,
      otpCode: otpCode,
    );
    _passwordResetEmail = email;
    _passwordResetToken = resetToken;
    debugPrint('[AuthService] OTP verification success. Reset token cached.');
  }

  Future<void> resetPassword({required String newPassword}) async {
    final resetToken = _passwordResetToken;
    if (resetToken == null || resetToken.isEmpty) {
      throw StateError('Missing reset token. Complete OTP verification first.');
    }

    debugPrint('[AuthService] Reset password flow started.');
    await _authRepository.resetPassword(
      token: resetToken,
      newPassword: newPassword,
    );
    _passwordResetToken = null;
    _passwordResetEmail = null;
    debugPrint(
      '[AuthService] Reset password success. Temporary reset state cleared.',
    );
  }

  Future<void> logout() async {
    debugPrint('[AuthService] Logout flow started.');
    final refreshToken = await _storageService.getRefreshToken();

    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _authRepository.logout(refreshToken: refreshToken);
        debugPrint('[AuthService] Logout API request succeeded.');
      } catch (e) {
        debugPrint('[AuthService] Logout API request failed: $e');
      }
    }

    await _storageService.clearAuth();
    debugPrint('[AuthService] Local auth state cleared.');
  }

  Future<bool> isAuthenticated() async {
    final authenticated = await _storageService.isAuthenticated();
    debugPrint('[AuthService] isAuthenticated=$authenticated');
    return authenticated;
  }

  bool isAuthenticatedSync() {
    final authenticated = _storageService.isAuthenticatedSync();
    debugPrint('[AuthService] isAuthenticatedSync=$authenticated');
    return authenticated;
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return '***';
    final local = parts[0];
    final domain = parts[1];
    if (local.length <= 2) return '${local[0]}***@$domain';
    return '${local.substring(0, 2)}***@$domain';
  }

  Future<String?> getAccessToken() => _storageService.getAccessToken();
}
