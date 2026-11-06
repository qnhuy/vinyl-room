import 'package:flutter/material.dart';
import '../../models/song.dart';
import '../../services/admin_service.dart';

/// Form Thêm mới hoặc Chỉnh sửa bài hát (Admin).
class AdminSongFormScreen extends StatefulWidget {
  final Song? song;

  const AdminSongFormScreen({super.key, this.song});

  @override
  State<AdminSongFormScreen> createState() => _AdminSongFormScreenState();
}

class _AdminSongFormScreenState extends State<AdminSongFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _lengthCtrl;
  late final TextEditingController _audioUrlCtrl;
  late final TextEditingController _coverUrlCtrl;

  int? _selectedArtistId;
  int? _selectedGenreId;

  List<Map<String, dynamic>> _artists = [];
  List<Map<String, dynamic>> _genres = [];

  bool _loading = false;
  bool _saving = false;

  bool get _isEditing => widget.song != null;

  @override
  void initState() {
    super.initState();
    final s = widget.song;
    _nameCtrl = TextEditingController(text: s?.musicName ?? '');
    _lengthCtrl = TextEditingController(text: s?.musicLength ?? '03:30');
    _audioUrlCtrl = TextEditingController(text: s?.audioUrl ?? '/musics/');
    _coverUrlCtrl = TextEditingController(text: s?.coverImageUrl ?? '');
    _loadMetadata();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _lengthCtrl.dispose();
    _audioUrlCtrl.dispose();
    _coverUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMetadata() async {
    setState(() => _loading = true);
    try {
      final a = await AdminService.instance.getArtists();
      final g = await AdminService.instance.getGenres();
      if (!mounted) return;
      setState(() {
        _artists = a;
        _genres = g;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final name = _nameCtrl.text.trim();
      final length = _lengthCtrl.text.trim();
      final audioUrl = _audioUrlCtrl.text.trim();
      final coverUrl = _coverUrlCtrl.text.trim();

      if (_isEditing) {
        await AdminService.instance.updateSong(
          musicId: widget.song!.musicId!,
          name: name,
          audioUrl: audioUrl,
          length: length,
          coverImageUrl: coverUrl.isEmpty ? null : coverUrl,
          artistId: _selectedArtistId,
          genreId: _selectedGenreId,
        );
      } else {
        await AdminService.instance.addSong(
          name: name,
          audioUrl: audioUrl,
          length: length,
          coverImageUrl: coverUrl.isEmpty ? null : coverUrl,
          artistId: _selectedArtistId,
          genreId: _selectedGenreId,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Đã cập nhật bài hát thành công!'
              : 'Đã thêm bài hát mới thành công!'),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('$e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Chỉnh sửa bài hát' : 'Thêm bài hát mới'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tên bài hát *',
                        prefixIcon: Icon(Icons.music_note),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Vui lòng nhập tên bài hát'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _audioUrlCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Đường dẫn file âm thanh (Audio URL) *',
                        hintText: '/musics/TenBaiHat.mp3 hoặc https://...',
                        prefixIcon: Icon(Icons.link),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Vui lòng nhập audio url'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lengthCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Thời lượng (mm:ss)',
                        prefixIcon: Icon(Icons.timer),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _coverUrlCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Đường dẫn ảnh bìa (Cover Image URL)',
                        hintText: 'https://... hoặc để trống',
                        prefixIcon: Icon(Icons.image),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedArtistId,
                      decoration: const InputDecoration(
                        labelText: 'Chọn Nghệ sĩ / Ca sĩ',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      items: _artists.map((a) {
                        return DropdownMenuItem<int>(
                          value: a['artist_id'] as int?,
                          child: Text('${a['artist_name'] ?? ''}'),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedArtistId = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedGenreId,
                      decoration: const InputDecoration(
                        labelText: 'Chọn Thể loại nhạc',
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(),
                      ),
                      items: _genres.map((g) {
                        return DropdownMenuItem<int>(
                          value: g['genre_id'] as int?,
                          child: Text('${g['genre_name'] ?? ''}'),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedGenreId = val),
                    ),
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: _saving ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _isEditing ? 'Lưu thay đổi' : 'Thêm bài hát',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
