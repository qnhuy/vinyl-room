import '../models/user.dart';
import '../services/admin_service.dart';

/// Giao diện View cho Quản trị Người dùng
abstract class AdminUserView {
  void showLoading();
  void hideLoading();
  void showUsers(List<User> users);
  void showError(String message);
  void showMessage(String message);
}

/// Presenter cho Quản trị Người dùng
class AdminUserPresenter {
  final AdminUserView _view;
  final AdminService _service = AdminService.instance;

  AdminUserPresenter(this._view);

  Future<void> loadUsers() async {
    _view.showLoading();
    try {
      final users = await _service.getAllUsers();
      _view.showUsers(users);
    } catch (e) {
      _view.showError('Không thể tải danh sách người dùng: $e');
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> toggleStatus(int userId, bool currentStatus) async {
    try {
      await _service.toggleUserStatus(userId, !currentStatus);
      _view.showMessage(
        !currentStatus ? 'Đã mở khóa tài khoản!' : 'Đã khóa tài khoản!',
      );
      await loadUsers();
    } catch (e) {
      _view.showError('$e');
    }
  }

  Future<void> updateRole(int userId, String newRole) async {
    try {
      await _service.updateUserRole(userId, newRole);
      _view.showMessage('Đã cập nhật vai trò thành công!');
      await loadUsers();
    } catch (e) {
      _view.showError('$e');
    }
  }
}
