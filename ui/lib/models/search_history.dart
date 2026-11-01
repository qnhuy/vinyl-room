/// Lớp đại diện cho lịch sử tìm kiếm bài hát của người dùng.
class SearchHistory {
  final int id;
  final String query;
  final DateTime? createdAt;

  SearchHistory({
    required this.id,
    required this.query,
    this.createdAt,
  });

  /// Chuyển đổi đối tượng thành Map (JSON)
  Map<String, dynamic> toMap() => {
    'id': id,
    'search_query': query,
    'created_at': createdAt?.toIso8601String(),
  };

  /// Chuyển đổi Map (JSON) từ API thành đối tượng SearchHistory
  factory SearchHistory.fromMap(Map<String, dynamic> map) {
    final rawId = map['id'];
    final id = rawId is int ? rawId : int.tryParse('$rawId') ?? 0;
    final query = map['search_query']?.toString() ??
        map['search_word']?.toString() ??
        map['keyword']?.toString() ??
        '';

    DateTime? createdAt;
    if (map['created_at'] != null) {
      createdAt = DateTime.tryParse('${map['created_at']}');
    }

    return SearchHistory(
      id: id,
      query: query,
      createdAt: createdAt,
    );
  }
}
