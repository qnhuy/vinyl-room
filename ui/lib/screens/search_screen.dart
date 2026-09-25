import 'package:flutter/material.dart';
import '../models/search_history.dart';
import '../models/song.dart';
import '../presenters/search_presenter.dart';
import '../services/music_service.dart';
import '../widgets/song_tile.dart';

/// Màn hình Tìm kiếm bài hát theo tên bài hát và hiển thị lịch sử tìm kiếm.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> implements SearchView {
  late final SearchPresenter _presenter;
  final _ctrl = TextEditingController();
  List<Song> _results = [];
  List<SearchHistory> _history = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _presenter = SearchPresenter(this);
    MusicService.changeNotifier.addListener(_onDataChanged);
    _presenter.loadHistory();
  }

  @override
  void dispose() {
    MusicService.changeNotifier.removeListener(_onDataChanged);
    _ctrl.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    if (!mounted) return;
    if (_ctrl.text.trim().isNotEmpty) {
      _presenter.search(_ctrl.text);
    } else {
      _presenter.loadHistory();
    }
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
  void showSearchResults(List<Song> songs) {
    if (mounted) {
      setState(() {
        _results = songs;
        _error = null;
      });
    }
  }

  @override
  void showSearchHistory(List<SearchHistory> history) {
    if (mounted) {
      setState(() {
        _history = history;
      });
    }
  }

  @override
  void showError(String message) {
    if (mounted) {
      setState(() => _error = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: false,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm tên bài hát...',
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _ctrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _ctrl.clear();
                      _presenter.search('');
                    },
                  )
                : null,
          ),
          onChanged: (text) => _presenter.search(text),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _ctrl.text.trim().isEmpty
                  ? _buildHistoryView()
                  : _buildResultsView(),
    );
  }

  Widget _buildHistoryView() {
    if (_history.isEmpty) {
      return const Center(child: Text('Nhập tên bài hát để tìm kiếm'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lịch sử tìm kiếm gần đây',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              TextButton(
                onPressed: () => _presenter.clearHistory(),
                child: const Text('Xóa tất cả'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _history.length,
            itemBuilder: (_, i) {
              final item = _history[i];
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(item.query),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => _presenter.deleteHistoryItem(item.id),
                ),
                onTap: () {
                  _ctrl.text = item.query;
                  _presenter.search(item.query);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultsView() {
    if (_results.isEmpty) {
      return const Center(child: Text('Không tìm thấy bài hát nào'));
    }

    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (_, i) {
        final song = _results[i];
        return SongTile(
          song: song,
          onTap: () => _presenter.playSong(song, _results),
        );
      },
    );
  }
}

// Alias tương thích
typedef SearchPage = SearchScreen;
