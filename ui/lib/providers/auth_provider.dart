import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/session.dart';

/// Provider quản lý trạng thái xác thực và phiên làm việc của người dùng.
class AuthProvider extends ChangeNotifier {
  AuthProvider._();
  static final AuthProvider instance = AuthProvider._();

  User? _user = Session.user;
  ThemeMode _themeMode = Session.themeMode;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  int get userId => _user?.userId ?? 0;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isPremium => _user?.hasActivePremium ?? false;
  int get remainingPremiumDays => _user?.remainingPremiumDays ?? 0;
  ThemeMode get themeMode => _themeMode;

  /// Khởi tạo và tải dữ liệu đã lưu từ SharedPreferences
  Future<void> init() async {
    await Session.load();
    _user = Session.user;
    _themeMode = Session.themeMode;
    notifyListeners();
  }

  /// Đăng nhập tài khoản
  Future<User> login(String username, String password) async {
    final u = await AuthService.instance.login(username, password);
    await Session.setUser(u);
    _user = u;
    notifyListeners();
    return u;
  }

  /// Đăng ký tài khoản
  Future<User> register(String username, String password, String? email) async {
    final u = await AuthService.instance.register(username, password, email);
    await Session.setUser(u);
    _user = u;
    notifyListeners();
    return u;
  }

  /// Đăng xuất tài khoản
  Future<void> logout() async {
    await Session.setUser(null);
    _user = null;
    notifyListeners();
  }

  /// Làm mới thông tin tài khoản và gói Premium từ máy chủ
  Future<void> refreshProfile() async {
    if (!isLoggedIn) return;
    try {
      final updated = await AuthService.instance.getProfile();
      await Session.setUser(updated);
      _user = updated;
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing profile: $e');
    }
  }

  /// Cập nhật trực tiếp trạng thái Premium của người dùng
  Future<void> updatePremiumStatus(bool isPremium, DateTime? expiresAt) async {
    if (_user == null) return;
    final updated = _user!.copyWith(
      isPremium: isPremium,
      premiumExpiresAt: expiresAt,
    );
    await Session.setUser(updated);
    _user = updated;
    notifyListeners();
  }

  /// Chuyển đổi giao diện sáng/tối
  Future<void> toggleTheme() async {
    await Session.toggleTheme();
    _themeMode = Session.themeMode;
    notifyListeners();
  }
}
