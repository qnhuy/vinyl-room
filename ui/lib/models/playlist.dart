/// Lớp đại diện cho đối tượng Playlist trong ứng dụng.
class Playlist {
  final int id;
  final int userId;
  final String playlistName;
  final int songCount;
  final String? description;
  final bool isShared;
  final String? ownerName;
  final bool isFavorite;

  Playlist({
    required this.id,
    required this.userId,
    required this.playlistName,
    this.songCount = 0,
    this.description,
    this.isShared = false,
    this.ownerName,
    this.isFavorite = false,
  });

  /// Getter tên hiển thị
  String get name => playlistName;

  /// Tạo bản sao mới với các thuộc tính được cập nhật
  Playlist copyWith({
    int? id,
    int? userId,
    String? playlistName,
    int? songCount,
    String? description,
    bool? isShared,
    String? ownerName,
    bool? isFavorite,
  }) {
    return Playlist(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      playlistName: playlistName ?? this.playlistName,
      songCount: songCount ?? this.songCount,
      description: description ?? this.description,
      isShared: isShared ?? this.isShared,
      ownerName: ownerName ?? this.ownerName,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// Chuyển đổi đối tượng Playlist thành Map (JSON)
  Map<String, dynamic> toMap() => {
    'user_playlist_id': id,
    'user_id': userId,
    'playlist_name': playlistName,
    'playlist_song_list_count': songCount,
    'description': description,
    'is_shared': isShared ? 1 : 0,
    'owner_name': ownerName,
    'is_favorite': isFavorite ? 1 : 0,
  };

  /// Chuyển đổi Map (JSON) từ API thành đối tượng Playlist
  factory Playlist.fromMap(Map<String, dynamic> map) {
    final rawId = map['user_playlist_id'] ?? map['playlist_id'];
    final id = rawId is int ? rawId : int.tryParse('$rawId') ?? 0;
    final rawCount = map['playlist_song_list_count'] ?? map['song_count'];
    final songCount = rawCount is int ? rawCount : int.tryParse('$rawCount') ?? 0;

    return Playlist(
      id: id,
      userId: map['user_id'] is int ? map['user_id'] as int : int.tryParse('${map['user_id']}') ?? 0,
      playlistName: map['playlist_name']?.toString() ?? '',
      songCount: songCount,
      description: map['description']?.toString(),
      isShared: (map['is_shared'] == 1 || map['is_shared'] == true),
      ownerName: map['owner_name']?.toString() ?? map['username']?.toString(),
      isFavorite: (map['is_favorite'] == 1 || map['is_favorite'] == true),
    );
  }
}
