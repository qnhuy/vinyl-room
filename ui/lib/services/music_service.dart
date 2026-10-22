import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/playlist.dart';
import '../models/search_history.dart';
import '../models/song.dart';
import '../utils/http.dart';
import 'session.dart';

/// Dịch vụ kết nối API âm nhạc (gọi API danh sách bài hát, xếp hạng, yêu thích, playlist).
class MusicService {
  MusicService._();
  static final MusicService instance = MusicService._();

  /// Quản lý thông báo thay đổi dữ liệu để tự động làm mới giao diện toàn ứng dụng.
  static final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);

  /// Phát thông báo khi có sự thay đổi dữ liệu (yêu thích, playlist).
  static void notifyChange() {
    changeNotifier.value++;
  }

  /// Trả về ID của người dùng đang đăng nhập.
  int get _uid => Session.userId;

  /// Giải mã dữ liệu JSON danh sách bài hát từ HTTP Response.
  List<Song> _decodeSongs(http.Response res) {
    if (res.statusCode != 200) {
      throw Exception('Lỗi API ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body) as List<dynamic>;
    return data
        .map((e) => Song.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Lấy toàn bộ danh sách bài hát từ server.
  Future<List<Song>> getAllSongs() async {
    final res = await Http.get('/music', queryParams: {'userId': _uid});
    return _decodeSongs(res);
  }

  /// Lấy danh sách bảng xếp hạng bài hát theo lượt nghe nhiều nhất.
  Future<List<Song>> getRanking() async {
    final res = await Http.get('/music/ranking', queryParams: {'userId': _uid});
    return _decodeSongs(res);
  }

  /// Lấy danh sách các bài hát yêu thích của người dùng.
  Future<List<Song>> getFavoriteSongs() async {
    if (_uid == 0) return [];
    final res = await Http.get('/music/favorites', queryParams: {'userId': _uid});
    return _decodeSongs(res);
  }

  /// Tìm kiếm bài hát theo từ khóa (hỗ trợ tiếng Việt có dấu).
  Future<List<Song>> searchSongs(String keyword) async {
    final res = await Http.get(
      '/music/search',
      queryParams: {'userId': _uid, 'q': keyword.trim()},
    );
    return _decodeSongs(res);
  }

  /// Thêm hoặc xóa bài hát khỏi danh sách yêu thích.
  Future<void> toggleFavorite(int musicId, bool isFavorite) async {
    if (_uid == 0) throw Exception('Hãy đăng nhập để sử dụng tính năng yêu thích!');
    final endpoint = '/users/$_uid/liked/$musicId';
    final res = isFavorite ? await Http.post(endpoint) : await Http.delete(endpoint);
    if (res.statusCode >= 300) throw Exception('Lỗi cập nhật yêu thích!');
    notifyChange();
  }

  /// Lấy danh sách các playlist do người dùng tạo.
  Future<List<Playlist>> getPlaylists() async {
    if (_uid == 0) return [];
    final res = await Http.get('/users/$_uid/playlists');
    if (res.statusCode != 200) return [];
    final list = jsonDecode(res.body) as List;
    return list
        .map((e) => Playlist.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Tạo một playlist mới với tên cho trước.
  Future<void> createPlaylist(String name) async {
    if (_uid == 0) throw Exception('Hãy đăng nhập!');
    final res = await Http.post(
      '/users/$_uid/playlists',
      body: {'playlist_name': name},
    );
    if (res.statusCode >= 300) throw Exception('Lỗi tạo playlist!');
    notifyChange();
  }

  /// Lấy 5 từ khóa tìm kiếm gần đây của người dùng.
  Future<List<SearchHistory>> getSearchHistory() async {
    if (_uid == 0) return [];
    final res = await Http.get('/users/$_uid/search-history');
    if (res.statusCode != 200) return [];
    final list = jsonDecode(res.body) as List;
    return list
        .map((e) => SearchHistory.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Xóa một mục từ khóa khỏi lịch sử tìm kiếm.
  Future<void> deleteSearchHistoryItem(int id) async {
    await Http.delete('/users/$_uid/search-history/$id');
  }

  /// Xóa toàn bộ lịch sử tìm kiếm của người dùng.
  Future<void> clearSearchHistory() async {
    await Http.delete('/users/$_uid/search-history');
  }

  /// Thêm một bài hát vào playlist chỉ định.
  Future<void> addToPlaylist(int playlistId, int musicId) async {
    if (_uid == 0) throw Exception('Hãy đăng nhập!');
    final res = await Http.post('/users/$_uid/playlists/$playlistId/music/$musicId');
    if (res.statusCode >= 300) {
      throw Exception('Không thêm được bài hát vào playlist!');
    }
    notifyChange();
  }

  /// Lấy danh sách các bài hát người dùng vừa nghe gần đây.
  Future<List<Song>> getRecentSongs() async {
    if (_uid == 0) return [];
    final res = await Http.get('/music/recent', queryParams: {'userId': _uid});
    return _decodeSongs(res);
  }

  /// Ghi nhận lượt nghe cho bài hát và tăng số lượt nghe.
  Future<void> logListen(int musicId) async {
    await Http.post(
      '/music/$musicId/listen',
      body: {'userId': _uid},
    );
  }

  /// Lấy danh sách toàn bộ bài hát có trong một playlist.
  Future<List<Song>> getPlaylistSongs(int playlistId) async {
    final res = await Http.get(
      '/playlists/$playlistId/songs',
      queryParams: {'userId': _uid},
    );
    return _decodeSongs(res);
  }

  /// Cập nhật trạng thái chia sẻ (Công khai / Riêng tư) cho playlist.
  Future<void> updatePlaylistShare(int playlistId, bool isShared) async {
    final res = await Http.put(
      '/playlists/$playlistId/share',
      body: {'is_shared': isShared ? 1 : 0},
    );
    if (res.statusCode >= 300) throw Exception('Không cập nhật được trạng thái chia sẻ!');
    notifyChange();
  }

  /// Lấy danh sách tất cả các playlist công khai từ những người dùng khác.
  Future<List<Playlist>> getPublicPlaylists() async {
    final res = await Http.get('/playlists/public', queryParams: {'userId': _uid});
    if (res.statusCode != 200) return [];
    final list = jsonDecode(res.body) as List;
    return list
        .map((e) => Playlist.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Thêm hoặc bỏ thích playlist công khai của người khác.
  Future<void> togglePlaylistFavorite(int playlistId, bool isFavorite) async {
    if (_uid == 0) throw Exception('Hãy đăng nhập!');
    final endpoint = '/users/$_uid/playlists/$playlistId/favorite';
    final res = isFavorite ? await Http.post(endpoint) : await Http.delete(endpoint);
    if (res.statusCode >= 300) throw Exception('Lỗi yêu thích playlist!');
    notifyChange();
  }

  /// Lấy danh sách các playlist công khai mà người dùng đã lưu/yêu thích.
  Future<List<Playlist>> getFavoritePlaylists() async {
    if (_uid == 0) return [];
    final res = await Http.get('/users/$_uid/favorite-playlists');
    if (res.statusCode != 200) return [];
    final list = jsonDecode(res.body) as List;
    return list
        .map((e) => Playlist.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Gợi ý AI: Tìm bài hát kế tiếp có giai điệu và tâm trạng tương đồng (Smart Flow).
  Future<Map<String, dynamic>?> getSmartNextSong(int currentMusicId) async {
    final res = await Http.get(
      '/music/$currentMusicId/smart-next',
      queryParams: {'userId': _uid},
    );
    if (res.statusCode != 200) return null;
    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }
}
