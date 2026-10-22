import '../models/song.dart';
import '../providers/player_provider.dart';
import '../services/music_service.dart';

/// Giao diện View cho Trang chi tiết Playlist (MVP Pattern).
abstract class PlaylistDetailView {
  void showLoading();
  void hideLoading();
  void showSongs(List<Song> songs);
  void showError(String message);
  void showMessage(String message);
}

/// Presenter cho Trang chi tiết Playlist.
class PlaylistDetailPresenter {
  final PlaylistDetailView _view;
  final MusicService _service = MusicService.instance;

  PlaylistDetailPresenter(this._view);

  Future<void> loadPlaylistSongs(int playlistId) async {
    _view.showLoading();
    try {
      final songs = await _service.getPlaylistSongs(playlistId);
      _view.showSongs(songs);
    } catch (e) {
      _view.showError('Không thể tải bài hát trong playlist: $e');
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> playSong(Song song, List<Song> list) async {
    try {
      await PlayerProvider.instance.playSong(song, list);
      if (song.musicId != null) {
        try {
          await _service.logListen(song.musicId!);
        } catch (_) {}
      }
    } catch (e) {
      _view.showError('Không phát được bài hát: $e');
    }
  }

  Future<void> toggleShare(int playlistId, bool isShared) async {
    try {
      await _service.updatePlaylistShare(playlistId, isShared);
    } catch (e) {
      _view.showError('Lỗi cập nhật trạng thái chia sẻ: $e');
      rethrow;
    }
  }

  Future<void> toggleFavorite(int playlistId, bool isFavorite) async {
    try {
      await _service.togglePlaylistFavorite(playlistId, isFavorite);
      _view.showMessage(
        isFavorite ? 'Đã lưu playlist vào yêu thích' : 'Đã bỏ yêu thích playlist',
      );
    } catch (e) {
      _view.showError('Lỗi yêu thích playlist: $e');
    }
  }

  Future<void> toggleSongFavorite(int musicId, bool isFavorite) async {
    try {
      await _service.toggleFavorite(musicId, isFavorite);
    } catch (e) {
      _view.showError('Lỗi cập nhật yêu thích bài hát: $e');
    }
  }
}
