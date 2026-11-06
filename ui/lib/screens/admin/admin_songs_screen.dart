import 'package:flutter/material.dart';
import '../../models/song.dart';
import '../../presenters/admin_song_presenter.dart';
import '../../widgets/cover_placeholder.dart';
import 'admin_song_form_screen.dart';

/// Màn hình Quản trị Kho Bài hát (CRUD Songs).
class AdminSongsScreen extends StatefulWidget {
  const AdminSongsScreen({super.key});

  @override
  State<AdminSongsScreen> createState() => _AdminSongsScreenState();
}

class _AdminSongsScreenState extends State<AdminSongsScreen>
    implements AdminSongView {
  late final AdminSongPresenter _presenter;
  List<Song> _allSongs = [];
  List<Song> _filteredSongs = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _presenter = AdminSongPresenter(this);
    _presenter.loadSongs();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void showLoading() {
    if (mounted) setState(() => _loading = true);
  }

  @override
  void hideLoading() {
    if (mounted) setState(() => _loading = false);
  }

  @override
  void showSongs(List<Song> songs) {
    if (mounted) {
      setState(() {
        _allSongs = songs;
        _filterSongs(_searchCtrl.text);
        _error = null;
      });
    }
  }

  @override
  void showError(String message) {
    if (mounted) {
      setState(() => _error = message);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _filterSongs(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      _filteredSongs = List.from(_allSongs);
    } else {
      _filteredSongs = _allSongs
          .where((s) =>
              s.title.toLowerCase().contains(q) ||
              s.artist.toLowerCase().contains(q))
          .toList();
    }
  }

  Future<void> _confirmDelete(Song song) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa bài hát'),
        content: Text(
            'Bạn có chắc chắn muốn xóa bài hát "${song.title}" khỏi hệ thống? Hành động này không thể hoàn tác!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (ok == true && song.musicId != null) {
      await _presenter.deleteSong(song.musicId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Kho Bài hát'),
        actions: [
          IconButton(
            onPressed: () => _presenter.loadSongs(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm bài hát hoặc ca sĩ...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _filterSongs(''));
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (text) => setState(() => _filterSongs(text)),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _filteredSongs.isEmpty
                        ? const Center(child: Text('Không tìm thấy bài hát nào'))
                        : RefreshIndicator(
                            onRefresh: () => _presenter.loadSongs(),
                            child: ListView.separated(
                              itemCount: _filteredSongs.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final song = _filteredSongs[i];
                                return ListTile(
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: song.coverImageUrl != null &&
                                            song.coverImageUrl!.isNotEmpty
                                        ? Image.network(
                                            song.coverImageUrl!,
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const CoverPlaceholder(
                                                    size: 48),
                                          )
                                        : const CoverPlaceholder(size: 48),
                                  ),
                                  title: Text(
                                    song.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    '${song.artist} • ${song.musicLength} • ${song.luotNghe} lượt nghe',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.blueAccent),
                                        tooltip: 'Sửa',
                                        onPressed: () async {
                                          final updated = await Navigator.push<bool>(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  AdminSongFormScreen(
                                                      song: song),
                                            ),
                                          );
                                          if (updated == true) {
                                            _presenter.loadSongs();
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.redAccent),
                                        tooltip: 'Xóa',
                                        onPressed: () => _confirmDelete(song),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminSongFormScreen(),
            ),
          );
          if (added == true) {
            _presenter.loadSongs();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm bài hát'),
      ),
    );
  }
}
