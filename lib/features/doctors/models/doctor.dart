import 'package:flutter/material.dart';

class Doctor {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String specialization;
  final String? profileImage;
  final bool isActive;
  final DateTime? createdAt;

  // UI-specific mock properties
  final String experience;
  final Color specialtyColor;
  final bool isPending;

  Doctor({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.specialization,
    this.profileImage,
    required this.isActive,
    this.createdAt,
    this.experience = '',
    this.specialtyColor = Colors.grey,
    this.isPending = false,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) => Doctor(
        id: json['id'],
        name: json['name'],
        email: json['email'] ?? '',
        phone: json['phone'] ?? '',
        specialization: json['specialization'] ?? '',
        profileImage: json['profile_image'],
        isActive: json['is_active'] ?? true,
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'specialization': specialization,
        'profile_image': profileImage,
        'is_active': isActive,
      };
}
