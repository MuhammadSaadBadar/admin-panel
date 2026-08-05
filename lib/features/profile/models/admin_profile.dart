import 'package:flutter/foundation.dart';

/// Represents the authenticated admin's profile as returned by
/// `GET /auth/me/`.
///
/// For an Admin account both `patient_profile` and `doctor_profile` are
/// always `null`, so this model only carries the top-level user fields.
class AdminProfile {
  final int id;
  final String email;
  final String role;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final bool isEmailVerified;
  final DateTime? dateJoined;

  const AdminProfile({
    required this.id,
    required this.email,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.isEmailVerified,
    this.dateJoined,
  });

  /// The admin's full name, falling back to email local-part when names are
  /// empty (the backend may return blank names for some accounts).
  String get fullName {
    final combined = '$firstName $lastName'.trim();
    if (combined.isNotEmpty) return combined;
    final at = email.indexOf('@');
    return at > 0 ? email.substring(0, at) : 'Admin';
  }

  /// Initials derived from the full name (max 2 letters) for avatar badges.
  String get initials {
    final parts = fullName
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0])
        .toList();
    return parts.isEmpty ? 'A' : parts.join().toUpperCase();
  }

  factory AdminProfile.fromJson(Map<String, dynamic> json) {
    final firstName = (json['first_name'] as String?) ?? '';
    final lastName = (json['last_name'] as String?) ?? '';

    DateTime? joined;
    final rawJoined = json['date_joined'];
    if (rawJoined is String && rawJoined.isNotEmpty) {
      joined = DateTime.tryParse(rawJoined);
    }

    final profile = AdminProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      email: (json['email'] as String?) ?? '',
      role: (json['role'] as String?) ?? 'admin',
      firstName: firstName,
      lastName: lastName,
      phoneNumber: (json['phone_number'] as String?) ?? '',
      isEmailVerified: (json['is_email_verified'] as bool?) ?? false,
      dateJoined: joined,
    );
    debugPrint(
      '[AdminProfile.fromJson] parsed — id=${profile.id} '
      'email=${profile.email} isEmailVerified=${profile.isEmailVerified}',
    );
    return profile;
  }
}
