import '../models/search_history.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../services/music_service.dart';

/// Giao diện View cho Tìm kiếm
abstract class SearchView {
  void showLoading();
  void hideLoading();
  void showSearchResults(List<Song> songs);
  void showSearchHistory(List<SearchHistory> history);
  void showError(String message);
}

/// Presenter cho Tìm kiếm bài hát
class SearchPresenter {
  final SearchView _view;
  final MusicService _service = MusicService.instance;

  SearchPresenter(this._view);

  Future<void> loadHistory() async {
    try {
      final history = await _service.getSearchHistory();
      _view.showSearchHistory(history);
    } catch (_) {}
  }

  Future<void> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      await loadHistory();
      _view.showSearchResults([]);
      return;
    }
    _view.showLoading();
    try {
      final results = await _service.searchSongs(q);
      _view.showSearchResults(results);
    } catch (e) {
      _view.showError('Lỗi tìm kiếm: $e');
    } finally {
      _view.hideLoading();
    }
  }

  Future<void> deleteHistoryItem(int id) async {
    await _service.deleteSearchHistoryItem(id);
    await loadHistory();
  }

  Future<void> clearHistory() async {
    await _service.clearSearchHistory();
    await loadHistory();
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
