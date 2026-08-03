import 'patient.dart';

class PaginatedPatients {
  final int count;
  final String? next;
  final String? previous;
  final List<Patient> results;

  PaginatedPatients({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedPatients.fromJson(Map<String, dynamic> json) => PaginatedPatients(
        count: json['count'] ?? 0,
        next: json['next'],
        previous: json['previous'],
        results: json['results'] != null
            ? List<Patient>.from(json['results'].map((x) => Patient.fromJson(x)))
            : [],
      );
}
