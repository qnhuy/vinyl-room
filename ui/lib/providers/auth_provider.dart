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

  /// Chuyển đổi giao diện sáng/tối
  Future<void> toggleTheme() async {
    await Session.toggleTheme();
    _themeMode = Session.themeMode;
    notifyListeners();
  }
}
