enum RiskLevel { high, normal }

class Vitals {
  final int waterIntake;
  final String kicks;
  final String bloodPressure;
  final bool isBpNormal;

  const Vitals({
    required this.waterIntake,
    required this.kicks,
    required this.bloodPressure,
    required this.isBpNormal,
  });
}

class PatientProfile {
  final String? dateOfBirth;
  final String? lmpDate;
  final String? eddDate;
  final String? bloodGroup;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? address;

  PatientProfile({
    this.dateOfBirth,
    this.lmpDate,
    this.eddDate,
    this.bloodGroup,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.address,
  });

  factory PatientProfile.fromJson(Map<String, dynamic> json) => PatientProfile(
    dateOfBirth: json['date_of_birth'],
    lmpDate: json['lmp_date'],
    eddDate: json['edd_date'],
    bloodGroup: json['blood_group'],
    emergencyContactName: json['emergency_contact_name'],
    emergencyContactPhone: json['emergency_contact_phone'],
    address: json['address'],
  );

  Map<String, dynamic> toJson() => {
    'date_of_birth': dateOfBirth,
    'lmp_date': lmpDate,
    'edd_date': eddDate,
    'blood_group': bloodGroup,
    'emergency_contact_name': emergencyContactName,
    'emergency_contact_phone': emergencyContactPhone,
    'address': address,
  };
}

class Patient {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final bool isActive;
  final DateTime? dateJoined;
  final PatientProfile? patientProfile;

  // UI-specific mock properties
  final RiskLevel riskLevel;
  final String trimester;
  final int week;
  final String doctor;
  final Vitals vitals;

  Patient({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.isActive,
    this.dateJoined,
    this.patientProfile,
    this.riskLevel = RiskLevel.normal,
    this.trimester = '',
    this.week = 0,
    this.doctor = '',
    this.vitals = const Vitals(
      waterIntake: 0,
      kicks: '',
      bloodPressure: '',
      isBpNormal: true,
    ),
  });

  String get name => '$firstName $lastName'.trim();

  int get age {
    if (patientProfile?.dateOfBirth != null) {
      final dob = DateTime.tryParse(patientProfile!.dateOfBirth!);
      if (dob != null) {
        final now = DateTime.now();
        int age = now.year - dob.year;
        if (now.month < dob.month ||
            (now.month == dob.month && now.day < dob.day)) {
          age--;
        }
        return age;
      }
    }
    return 0;
  }

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
    id: json['id'] ?? 0,
    email: json['email'] ?? '',
    firstName: json['first_name'] ?? '',
    lastName: json['last_name'] ?? '',
    phoneNumber: json['phone_number'] ?? '',
    isActive: json['is_active'] ?? true,
    dateJoined: json['date_joined'] != null
        ? DateTime.tryParse(json['date_joined'])
        : null,
    patientProfile: json['patient_profile'] != null
        ? PatientProfile.fromJson(json['patient_profile'])
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'first_name': firstName,
    'last_name': lastName,
    'phone_number': phoneNumber,
    'is_active': isActive,
    'date_joined': dateJoined?.toIso8601String(),
    'patient_profile': patientProfile?.toJson(),
  };
}
