import '../models/playlist.dart';
import '../models/song.dart';
import '../services/music_service.dart';
import '../services/session.dart';

/// Giao diện View cho Trang cá nhân (MVP Pattern).
abstract class ProfileView {
  void showLoading();
  void hideLoading();
  void showProfileData({
    required List<Song> liked,
    required List<Playlist> playlists,
    required List<Playlist> favPlaylists,
  });
  void showError(String message);
  void showMessage(String message);
}

/// Presenter điều phối dữ liệu Trang cá nhân.
class ProfilePresenter {
  final ProfileView _view;
  final MusicService _service = MusicService.instance;

  ProfilePresenter(this._view);

  Future<void> loadProfileData() async {
    if (!Session.isLoggedIn) {
      _view.showProfileData(liked: [], playlists: [], favPlaylists: []);
      return;
    }

    _view.showLoading();
    try {
      final fav = await _service.getFavoriteSongs();
      final pl = await _service.getPlaylists();
      final fpl = await _service.getFavoritePlaylists();

      _view.showProfileData(
        liked: fav,
        playlists: pl,
        favPlaylists: fpl,
      );
    } catch (e) {
      _view.showError('Không thể tải dữ liệu cá nhân: $e');
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> createPlaylist(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    try {
      await _service.createPlaylist(trimmed);
      _view.showMessage('Đã tạo playlist thành công');
      await loadProfileData();
    } catch (e) {
      _view.showError('Lỗi tạo playlist: $e');
    }
  }
}
