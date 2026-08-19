import 'package:flutter/material.dart';

class Doctor {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final bool isActive;
  final DateTime? dateJoined;

  // Nested doctor_profile fields
  final String specialization;
  final String licenseNumber;
  final int yearsOfExperience;
  final String bio;
  final bool isAcceptingPatients;

  // UI/legacy fields (kept for backward compatibility with other screens)
  final String? profileImage;
  final String city;
  final double rating;
  final int reviews;
  final bool isAssigned;
  final Color specialtyColor;
  final bool isPending;

  Doctor({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.isActive,
    this.dateJoined,
    this.specialization = '',
    this.licenseNumber = '',
    this.yearsOfExperience = 0,
    this.bio = '',
    this.isAcceptingPatients = false,
    this.profileImage,
    this.city = 'Unknown',
    this.rating = 0.0,
    this.reviews = 0,
    this.isAssigned = false,
    this.specialtyColor = Colors.grey,
    this.isPending = false,
  });

  /// Full display name (first + last).
  String get name {
    final parts = [firstName, lastName].where((p) => p.isNotEmpty);
    return parts.isEmpty ? 'Unknown Doctor' : parts.join(' ');
  }

  /// Legacy alias for [phoneNumber].
  String get phone => phoneNumber;

  /// Legacy alias — experience label derived from years of experience.
  String get experience {
    if (yearsOfExperience <= 0) return '';
    return '$yearsOfExperience Years Experience';
  }

  /// Returns a copy of this [Doctor] with the given fields replaced.
  ///
  /// Used to rebuild a doctor from a partial PATCH response while preserving
  /// the original ID (and any other fields the backend did not include).
  Doctor copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    bool? isActive,
    DateTime? dateJoined,
    String? specialization,
    String? licenseNumber,
    int? yearsOfExperience,
    String? bio,
    bool? isAcceptingPatients,
    String? profileImage,
    String? city,
    double? rating,
    int? reviews,
    bool? isAssigned,
    bool? isPending,
  }) {
    return Doctor(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isActive: isActive ?? this.isActive,
      dateJoined: dateJoined ?? this.dateJoined,
      specialization: specialization ?? this.specialization,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      bio: bio ?? this.bio,
      isAcceptingPatients: isAcceptingPatients ?? this.isAcceptingPatients,
      profileImage: profileImage ?? this.profileImage,
      city: city ?? this.city,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
      isAssigned: isAssigned ?? this.isAssigned,
      isPending: isPending ?? this.isPending,
    );
  }

  factory Doctor.fromJson(Map<String, dynamic> json) {
    // Parse nested doctor_profile if present.
    final profile = json['doctor_profile'] is Map
        ? (json['doctor_profile'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};

    return Doctor(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      isActive: json['is_active'] ?? true,
      dateJoined: json['date_joined'] != null
          ? DateTime.tryParse(json['date_joined'].toString())
          : null,
      specialization: profile['specialization'] ?? '',
      licenseNumber: profile['license_number'] ?? '',
      yearsOfExperience: profile['years_of_experience'] ?? 0,
      bio: profile['bio'] ?? '',
      isAcceptingPatients: profile['is_accepting_patients'] ?? false,
      profileImage: json['profile_image'],
      city: json['city'] ?? 'Unknown',
      rating: (json['rating'] ?? 0).toDouble(),
      reviews: json['reviews'] ?? 0,
      isAssigned: json['is_assigned'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'phone_number': phoneNumber,
    'is_active': isActive,
    'doctor_profile': {
      'specialization': specialization,
      'license_number': licenseNumber,
      'years_of_experience': yearsOfExperience,
      'bio': bio,
      'is_accepting_patients': isAcceptingPatients,
    },
    'profile_image': profileImage,
    'city': city,
    'rating': rating,
    'reviews': reviews,
    'is_assigned': isAssigned,
  };
}
