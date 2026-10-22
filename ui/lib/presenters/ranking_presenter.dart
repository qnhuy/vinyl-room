import '../models/song.dart';
import '../providers/player_provider.dart';
import '../services/music_service.dart';

/// Giao diện View cho Bảng xếp hạng
abstract class RankingView {
  void showLoading();
  void hideLoading();
  void showRanking(List<Song> songs);
  void showError(String message);
}

/// Presenter cho Bảng xếp hạng
class RankingPresenter {
  final RankingView _view;
  final MusicService _service = MusicService.instance;

  RankingPresenter(this._view);

  Future<void> loadRanking() async {
    _view.showLoading();
    try {
      final songs = await _service.getRanking();
      _view.showRanking(songs);
    } catch (e) {
      _view.showError('Không thể tải bảng xếp hạng: $e');
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
}
