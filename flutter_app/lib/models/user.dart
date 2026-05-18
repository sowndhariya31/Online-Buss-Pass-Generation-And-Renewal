class User {
  final int id;
  final String username;
  final String email;
  final String phoneNumber;
  final String role;
  final String? routeFrom;
  final String? routeTo;
  final String? college;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.routeFrom,
    this.routeTo,
    this.college,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone'] ?? '',
      role: json['role'] ?? 'STUDENT',
      routeFrom: json['route_from'],
      routeTo: json['route_to'],
      college: json['college'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone_number': phoneNumber,
      'role': role,
      'route_from': routeFrom,
      'route_to': routeTo,
      'college': college,
    };
  }
}
