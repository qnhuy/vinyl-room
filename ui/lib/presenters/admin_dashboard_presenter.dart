import '../services/admin_service.dart';

/// Giao diện View cho Màn hình Thống kê Admin Dashboard
abstract class AdminDashboardView {
  void showLoading();
  void hideLoading();
  void showStats(Map<String, dynamic> stats);
  void showError(String message);
}

/// Presenter điều phối dữ liệu Dashboard Thống kê Admin
class AdminDashboardPresenter {
  final AdminDashboardView _view;
  final AdminService _service = AdminService.instance;

  AdminDashboardPresenter(this._view);

  Future<void> loadDashboard() async {
    _view.showLoading();
    try {
      final stats = await _service.getDashboardStats();
      _view.showStats(stats);
    } catch (e) {
      _view.showError('Không thể tải dữ liệu thống kê: $e');
    } finally {
      _view.hideLoading();
    }
  }
}
