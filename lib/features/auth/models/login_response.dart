import 'package:admin/features/auth/models/admin_user.dart';

class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final AdminUser? user;
  final String? role;
  final int? userId;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    this.user,
    this.role,
    this.userId,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    return LoginResponse(
      accessToken: (json['access'] ?? json['token'] ?? '') as String,
      refreshToken: (json['refresh'] ?? json['refresh_token'] ?? '') as String,
      role: json['role'] as String?,
      userId: json['user_id'] as int?,
      user: userJson is Map<String, dynamic>
          ? AdminUser.fromJson(userJson)
          : null,
    );
  }
}
