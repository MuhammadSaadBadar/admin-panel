class AdminUser {
  final int id;
  final String email;
  final String name;
  final String role;

  AdminUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: json['id'],
        email: json['email'],
        name: json['name'],
        role: json['role'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role,
      };
}

