class User {
  final int id;
  final String email;
  final String username;
  final String phone;
  final String? token; // 로그인 시 토큰 저장
  final String role;


  User({required this.id, required this.email, required this.username, required this.phone, this.token,required this.role});

  factory User.fromJson(Map<String, dynamic> json, {String? token}) {
    return User(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      phone: json['phone'],
      role: json['role'] ?? 'general',
      token: token,
    );
  }
}