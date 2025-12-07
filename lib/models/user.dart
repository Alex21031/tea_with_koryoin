class User {
  final String id;
  final String email;
  final String name;
  final String username;
  final String phone;
  final String? certificatePath; // 전문가 인증 요청 플래그
  final String? role;
  final String? token;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.username,
    required this.phone,
    this.certificatePath,
    this.role,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json, {String? token}) {
    return User(
      id: json['id'].toString(),
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      phone: json['phone'] ?? '',
      certificatePath: json['certificate_path'],
      role: json['role'] ?? 'user',
      token: token ?? json['token'],
    );
  }

  // [추가됨] 현재 객체를 복사하면서 특정 필드만 변경하는 메서드
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? username,
    String? phone,
    String? certificatePath, // 이 필드를 업데이트하기 위함
    String? role,
    String? token,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      certificatePath: certificatePath ?? this.certificatePath, // 로컬 상태 업데이트
      role: role ?? this.role,
      token: token ?? this.token,
    );
  }
}