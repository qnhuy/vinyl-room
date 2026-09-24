/// Lớp đại diện cho đối tượng Người dùng (User) trong ứng dụng.
class User {
  final int? userId;
  final String username;
  final String password;
  final String? email;
  final String? avatarUrl;
  final String role;
  final int isActive;

  User({
    this.userId,
    required this.username,
    required this.password,
    this.email,
    this.avatarUrl,
    this.role = 'user',
    this.isActive = 1,
  });

  /// Kiểm tra tài khoản có quyền Quản trị viên hay không
  bool get isAdmin => role.trim().toLowerCase() == 'admin';

  /// Tạo bản sao đối tượng với các thuộc tính thay đổi
  User copyWith({
    int? userId,
    String? username,
    String? password,
    String? email,
    String? avatarUrl,
    String? role,
    int? isActive,
  }) {
    return User(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      password: password ?? this.password,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Chuyển đổi đối tượng User thành Map (JSON).
  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'username': username,
    'password': password,
    'email': email,
    'avatar_url': avatarUrl,
    'role': role,
    'isActive': isActive,
  };

  /// Chuyển đổi Map (JSON) từ API thành đối tượng User.
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userId: map['user_id'] is int
          ? map['user_id'] as int
          : int.tryParse('${map['user_id']}'),
      username: map['username']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      email: map['email']?.toString(),
      avatarUrl: map['avatar_url']?.toString(),
      role: map['role']?.toString() ?? 'user',
      isActive: map['isActive'] is int
          ? map['isActive'] as int
          : int.tryParse('${map['isActive']}') ?? 1,
    );
  }
}
