import '../models/playlist.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../services/music_service.dart';
import '../services/session.dart';

/// Giao diện View cho Màn hình Trang chủ (MVP Pattern).
abstract class HomeView {
  void showLoading();
  void hideLoading();
  void showHomeData({
    required List<Song> topSongs,
    required List<Song> recent,
    required List<Playlist> playlists,
  });
  void showError(String message);
  void showMessage(String message);
}

/// Presenter điều phối dữ liệu và logic nghiệp vụ cho Trang chủ.
class HomePresenter {
  final HomeView _view;
  final MusicService _service = MusicService.instance;

  HomePresenter(this._view);

  /// Tải dữ liệu trang chủ (Top bài hát hot, bài nghe gần đây, playlist của tôi)
  Future<void> loadHomeData() async {
    _view.showLoading();
    try {
      final ranking = await _service.getRanking();
      final topSongs = ranking.take(10).toList();

      final recent = Session.isLoggedIn
          ? await _service.getRecentSongs()
          : <Song>[];

      final playlists = Session.isLoggedIn
          ? await _service.getPlaylists()
          : <Playlist>[];

      _view.showHomeData(
        topSongs: topSongs,
        recent: recent,
        playlists: playlists,
      );
    } catch (e) {
      _view.showError('Không thể tải dữ liệu trang chủ: $e');
    } finally {
      _view.hideLoading();
    }
  }

  /// Phát bài hát và ghi nhận lượt nghe
  Future<void> playSong(Song song, List<Song> playlist) async {
    try {
      await PlayerProvider.instance.playSong(song, playlist);
      if (song.musicId != null) {
        try {
          await _service.logListen(song.musicId!);
        } catch (_) {}
      }
    } catch (e) {
      _view.showError('Không phát được bài hát: $e');
    }
  }
}
