import '../models/song.dart';
import '../services/admin_service.dart';

/// Giao diện View cho Quản trị Bài hát
abstract class AdminSongView {
  void showLoading();
  void hideLoading();
  void showSongs(List<Song> songs);
  void showError(String message);
  void showMessage(String message);
}

/// Presenter cho Quản trị Bài hát (CRUD)
class AdminSongPresenter {
  final AdminSongView _view;
  final AdminService _service = AdminService.instance;

  AdminSongPresenter(this._view);

  Future<void> loadSongs() async {
    _view.showLoading();
    try {
      final songs = await _service.getAllSongs();
      _view.showSongs(songs);
    } catch (e) {
      _view.showError('Không thể tải danh sách bài hát: $e');
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> deleteSong(int musicId) async {
    try {
      await _service.deleteSong(musicId);
      _view.showMessage('Đã xóa bài hát thành công!');
      await loadSongs();
    } catch (e) {
      _view.showError('Lỗi xóa bài hát: $e');
    }
  }
}
