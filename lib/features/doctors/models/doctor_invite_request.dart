/// Outbound payload for `POST /api/v1/accounts/doctors/invite/`.
///
/// Field names match the backend contract exactly (snake_case). The backend
/// creates a pending `DoctorInvite` and emails an accept link to the doctor.
class DoctorInviteRequest {
  final String email;
  final String specialization;

  const DoctorInviteRequest({
    required this.email,
    required this.specialization,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'specialization': specialization,
  };
}
