import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../config/config.dart';
import '../models/song.dart';
import '../services/music_service.dart';

/// Provider quản lý trình phát nhạc (AudioPlayer), hàng đợi bài hát và trạng thái phát.
class PlayerProvider extends ChangeNotifier {
  PlayerProvider._() {
    _initPlayerListener();
  }

  static final PlayerProvider instance = PlayerProvider._();

  final AudioPlayer _player = AudioPlayer();
  final ValueNotifier<int> playerChangeNotifier = ValueNotifier<int>(0);

  List<Song> queue = [];
  int index = 0;
  bool repeat = false;

  /// Chế độ AI Smart Flow: Tự động gợi ý & nối tiếp bài hát cùng tâm trạng khi hết hàng đợi
  bool isSmartFlow = true;
  String? currentAiReason;
  String? currentAiMood;
  bool isLoadingSmartSong = false;

  void _notifyPlayerChange() {
    playerChangeNotifier.value++;
    notifyListeners();
  }

  void _initPlayerListener() {
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (!repeat) {
          _handleAutoNext();
        }
      }
    });
  }

  /// Xử lý chuyển bài tự động khi bài hát kết thúc
  Future<void> _handleAutoNext() async {
    // 1. Nếu trong hàng đợi (Playlist / Album) vẫn còn bài tiếp theo
    if (queue.isNotEmpty && index < queue.length - 1) {
      currentAiReason = null;
      currentAiMood = null;
      await next();
      return;
    }

    // 2. Nếu đã hết hàng đợi hoặc đang nghe bài lẻ: Kiểm tra chế độ AI Smart Flow
    if (isSmartFlow) {
      await playSmartNextSong();
    } else {
      // Nếu lặp lại danh sách hoặc dừng
      if (queue.isNotEmpty) {
        index = 0;
        await _loadCurrent();
      }
    }
  }

  /// Bật/tắt chế độ AI Smart Flow
  void toggleSmartFlow() {
    isSmartFlow = !isSmartFlow;
    notifyListeners();
  }

  /// Gọi AI tìm và phát bài hát kế tiếp có mood tương đồng
  Future<void> playSmartNextSong() async {
    final cur = current;
    if (cur?.musicId == null) return;

    isLoadingSmartSong = true;
    notifyListeners();

    try {
      final res = await MusicService.instance.getSmartNextSong(cur!.musicId!);
      if (res != null && res['song'] != null) {
        final song = Song.fromMap(Map<String, dynamic>.from(res['song'] as Map));
        currentAiReason = res['reason']?.toString();
        currentAiMood = res['mood']?.toString();

        // Đưa bài hát mới vào hàng đợi và chuyển phát
        queue.add(song);
        index = queue.length - 1;
        _notifyPlayerChange();
        await _loadCurrent(autoPlay: true);

        // Ghi nhận lượt nghe
        if (song.musicId != null) {
          try {
            await MusicService.instance.logListen(song.musicId!);
          } catch (_) {}
        }
      } else {
        // Hết bài phù hợp -> dừng nhạc
        await stop();
      }
    } catch (e) {
      debugPrint('[SmartFlow Error]: $e');
    } finally {
      isLoadingSmartSong = false;
      notifyListeners();
    }
  }

  /// Trả về bài hát đang phát hiện tại.
  Song? get current =>
      queue.isEmpty || index < 0 || index >= queue.length ? null : queue[index];

  /// Trạng thái đang phát hay tạm dừng.
  bool get playing => _player.playing;

  /// Stream thời gian vị trí hiện tại.
  Stream<Duration> get positionStream => _player.positionStream;

  /// Stream tổng thời lượng bài hát.
  Stream<Duration?> get durationStream => _player.durationStream;

  /// Stream trạng thái phát nhạc.
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  /// Stream âm lượng.
  Stream<double> get volumeStream => _player.volumeStream;

  /// Mức âm lượng hiện tại (0.0 - 1.0).
  double get volume => _player.volume;

  /// Đặt mức âm lượng.
  Future<void> setVolume(double v) async {
    await _player.setVolume(v.clamp(0.0, 1.0));
    notifyListeners();
  }

  /// Chuẩn hóa đường dẫn URL.
  String resolveUrl(String rawUrl) {
    var url = rawUrl.trim();
    if (url.isEmpty) return '';

    final base = AppConfig.apiBaseUrl;

    if (url.contains('localhost:3000')) {
      url = url.replaceAll('http://localhost:3000', base);
      url = url.replaceAll('https://localhost:3000', base);
    } else if (url.contains('127.0.0.1:3000')) {
      url = url.replaceAll('http://127.0.0.1:3000', base);
      url = url.replaceAll('https://127.0.0.1:3000', base);
    } else if (url.contains('10.0.2.2:3000')) {
      url = url.replaceAll('http://10.0.2.2:3000', base);
      url = url.replaceAll('https://10.0.2.2:3000', base);
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (!url.startsWith('/')) {
        url = '/$url';
      }
      url = '$base$url';
    }

    return url;
  }

  /// Thiết lập hàng đợi danh sách bài hát và phát từ vị trí chỉ định.
  Future<void> setQueue(List<Song> songs, {int startIndex = 0}) async {
    queue = List<Song>.from(songs);
    index = startIndex.clamp(0, queue.isEmpty ? 0 : queue.length - 1);
    currentAiReason = null;
    currentAiMood = null;
    _notifyPlayerChange();
    await _loadCurrent(autoPlay: true);
  }

  /// Phát một bài hát cụ thể trong danh sách.
  Future<void> playSong(Song song, List<Song> fromList) async {
    final i = fromList.indexWhere((s) => s.musicId == song.musicId);
    await setQueue(fromList, startIndex: i >= 0 ? i : 0);
  }

  /// Tải và phát bài hát hiện tại ở vị trí `index`.
  Future<void> _loadCurrent({bool autoPlay = true}) async {
    final song = current;
    if (song == null) return;

    _notifyPlayerChange();

    final rawUrl = song.audioUrl.trim();
    if (rawUrl.isEmpty) {
      throw Exception('Bài hát chưa có đường dẫn audio_url');
    }

    final url = resolveUrl(rawUrl);

    try {
      await _player.stop();
      await _player.setUrl(url);
      await _player.setLoopMode(repeat ? LoopMode.one : LoopMode.off);
      if (autoPlay) {
        await _player.play();
      }
    } catch (e) {
      throw Exception('Lỗi phát nhạc ($url): $e');
    }
  }

  /// Chuyển đổi trạng thái Phát / Tạm dừng.
  Future<void> togglePlay() async {
    if (current == null) return;
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
    notifyListeners();
  }

  /// Chuyển sang bài tiếp theo.
  Future<void> next() async {
    if (queue.isEmpty) return;
    index = (index + 1) % queue.length;
    await _loadCurrent();
  }

  /// Quay lại bài trước đó.
  Future<void> previous() async {
    if (queue.isEmpty) return;
    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
      return;
    }
    if (index > 0) {
      index--;
    } else {
      index = queue.length - 1;
    }
    await _loadCurrent();
  }

  /// Bật/tắt chế độ lặp lại.
  Future<void> toggleRepeat() async {
    repeat = !repeat;
    await _player.setLoopMode(repeat ? LoopMode.one : LoopMode.off);
    notifyListeners();
  }

  /// Tua nhạc đến vị trí thời gian `position`.
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// Dừng phát nhạc hoàn toàn và xóa hàng đợi.
  Future<void> stop() async {
    await _player.stop();
    queue = [];
    index = 0;
    currentAiReason = null;
    currentAiMood = null;
    _notifyPlayerChange();
  }

  /// Cập nhật trạng thái yêu thích của bài hát đang phát.
  void updateCurrentFavorite(bool isFavorite) {
    final c = current;
    if (c == null) return;
    queue[index] = c.copyWith(isFavorite: isFavorite);
    _notifyPlayerChange();
  }

  /// Cập nhật trạng thái yêu thích của bài hát trong toàn bộ hàng đợi.
  void updateSongFavorite(int musicId, bool isFavorite) {
    for (int i = 0; i < queue.length; i++) {
      if (queue[i].musicId == musicId) {
        queue[i] = queue[i].copyWith(isFavorite: isFavorite);
      }
    }
    _notifyPlayerChange();
  }
}
