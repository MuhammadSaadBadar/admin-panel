/// Outbound payload for `POST /api/v1/auth/register/`.
///
/// Field names match the backend contract exactly (snake_case). The backend
/// always creates a `role=patient` account and sends a verification email —
/// the account cannot log in until `verify-email/` is called with the token
/// from that email.
class PatientRegistrationRequest {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String phoneNumber;

  const PatientRegistrationRequest({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'first_name': firstName,
    'last_name': lastName,
    'phone_number': phoneNumber,
  };
}
