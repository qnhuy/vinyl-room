/// Lớp đại diện cho đối tượng Người dùng (User) trong ứng dụng.
class User {
  final int? userId;
  final String username;
  final String password;
  final String? email;
  final String? avatarUrl;
  final String role;
  final int isActive;
  final bool isPremium;
  final DateTime? premiumExpiresAt;

  User({
    this.userId,
    required this.username,
    required this.password,
    this.email,
    this.avatarUrl,
    this.role = 'user',
    this.isActive = 1,
    this.isPremium = false,
    this.premiumExpiresAt,
  });

  /// Kiểm tra tài khoản có quyền Quản trị viên hay không
  bool get isAdmin => role.trim().toLowerCase() == 'admin';

  /// Kiểm tra tài khoản có gói Vinyl Premium đang hoạt động hay không
  bool get hasActivePremium {
    if (!isPremium) return false;
    if (premiumExpiresAt == null) return true;
    return premiumExpiresAt!.isAfter(DateTime.now());
  }

  /// Số ngày sử dụng gói Premium còn lại
  int get remainingPremiumDays {
    if (!hasActivePremium) return 0;
    if (premiumExpiresAt == null) return 999;
    final diff = premiumExpiresAt!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff + 1;
  }

  /// Tạo bản sao đối tượng với các thuộc tính thay đổi
  User copyWith({
    int? userId,
    String? username,
    String? password,
    String? email,
    String? avatarUrl,
    String? role,
    int? isActive,
    bool? isPremium,
    DateTime? premiumExpiresAt,
  }) {
    return User(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      password: password ?? this.password,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
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
    'is_premium': isPremium ? 1 : 0,
    'premium_expires_at': premiumExpiresAt?.toIso8601String(),
  };

  /// Chuyển đổi Map (JSON) từ API thành đối tượng User.
  factory User.fromMap(Map<String, dynamic> map) {
    DateTime? expiresAt;
    final expRaw = map['premium_expires_at'];
    if (expRaw != null && expRaw.toString().isNotEmpty) {
      expiresAt = DateTime.tryParse(expRaw.toString());
    }

    final rawPremium = map['is_premium'];
    final bool isPrem = rawPremium == 1 || rawPremium == true || rawPremium == '1';

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
      isPremium: isPrem,
      premiumExpiresAt: expiresAt,
    );
  }
}
