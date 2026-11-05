import 'dart:convert';
import '../models/song.dart';
import '../models/user.dart';
import '../utils/http.dart';

/// Dịch vụ kết nối API Quản trị viên (Admin API Service).
class AdminService {
  AdminService._();
  static final AdminService instance = AdminService._();

  /// 1. Kiểm tra xác thực quyền Quản trị viên
  Future<bool> verifyAdminAccess() async {
    final res = await Http.get('/admin/check');
    return res.statusCode == 200;
  }

  /// 2. Lấy dữ liệu thống kê Dashboard (KPI, Top bài hát, Top tìm kiếm)
  Future<Map<String, dynamic>> getDashboardStats() async {
    final res = await Http.get('/admin/stats');
    if (res.statusCode != 200) {
      throw Exception('Không thể tải dữ liệu thống kê: ${res.body}');
    }
    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }

  /// 3. Lấy toàn bộ danh sách bài hát trong hệ thống
  Future<List<Song>> getAllSongs() async {
    final res = await Http.get('/admin/songs');
    if (res.statusCode != 200) {
      throw Exception('Lỗi lấy danh sách bài hát: ${res.body}');
    }
    final list = jsonDecode(res.body) as List;
    return list
        .map((e) => Song.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// 4. Thêm bài hát mới vào hệ thống
  Future<void> addSong({
    required String name,
    required String audioUrl,
    String? length,
    String? coverImageUrl,
    int? artistId,
    int? albumId,
    int? genreId,
  }) async {
    final res = await Http.post(
      '/admin/songs',
      body: {
        'music_name': name,
        'audio_url': audioUrl,
        'music_length': length ?? '03:30',
        'cover_image_url': coverImageUrl,
        'artist_id': artistId,
        'album_id': albumId,
        'genre_id': genreId,
      },
    );

    if (res.statusCode >= 300) {
      final err = jsonDecode(res.body);
      throw Exception(err['error'] ?? 'Không thể thêm bài hát!');
    }
  }

  /// 5. Chỉnh sửa bài hát
  Future<void> updateSong({
    required int musicId,
    required String name,
    required String audioUrl,
    String? length,
    String? coverImageUrl,
    int? artistId,
    int? albumId,
    int? genreId,
  }) async {
    final res = await Http.put(
      '/admin/songs/$musicId',
      body: {
        'music_name': name,
        'audio_url': audioUrl,
        'music_length': length ?? '03:30',
        'cover_image_url': coverImageUrl,
        'artist_id': artistId,
        'album_id': albumId,
        'genre_id': genreId,
      },
    );

    if (res.statusCode >= 300) {
      final err = jsonDecode(res.body);
      throw Exception(err['error'] ?? 'Không thể cập nhật bài hát!');
    }
  }

  /// 6. Xóa bài hát khỏi hệ thống
  Future<void> deleteSong(int musicId) async {
    final res = await Http.delete('/admin/songs/$musicId');
    if (res.statusCode >= 300) {
      final err = jsonDecode(res.body);
      throw Exception(err['error'] ?? 'Không thể xóa bài hát!');
    }
  }

  /// 7. Lấy danh sách toàn bộ người dùng
  Future<List<User>> getAllUsers() async {
    final res = await Http.get('/admin/users');
    if (res.statusCode != 200) {
      throw Exception('Lỗi lấy danh sách người dùng: ${res.body}');
    }
    final list = jsonDecode(res.body) as List;
    return list
        .map((e) => User.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// 8. Khóa hoặc Mở khóa tài khoản người dùng
  Future<void> toggleUserStatus(int userId, bool isActive) async {
    final res = await Http.put(
      '/admin/users/$userId/status',
      body: {'isActive': isActive ? 1 : 0},
    );
    if (res.statusCode >= 300) {
      final err = jsonDecode(res.body);
      throw Exception(err['error'] ?? 'Lỗi cập nhật trạng thái người dùng!');
    }
  }

  /// 9. Đổi vai trò (Role: user <-> admin)
  Future<void> updateUserRole(int userId, String newRole) async {
    final res = await Http.put(
      '/admin/users/$userId/role',
      body: {'role': newRole},
    );
    if (res.statusCode >= 300) {
      final err = jsonDecode(res.body);
      throw Exception(err['error'] ?? 'Lỗi cập nhật vai trò người dùng!');
    }
  }

  /// 10. Lấy danh mục Nghệ sĩ cho dropdown
  Future<List<Map<String, dynamic>>> getArtists() async {
    final res = await Http.get('/admin/artists');
    if (res.statusCode != 200) return [];
    return (jsonDecode(res.body) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  /// 11. Lấy danh mục Thể loại cho dropdown
  Future<List<Map<String, dynamic>>> getGenres() async {
    final res = await Http.get('/admin/genres');
    if (res.statusCode != 200) return [];
    return (jsonDecode(res.body) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }
}
