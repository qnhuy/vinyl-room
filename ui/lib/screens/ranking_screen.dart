import 'package:flutter/material.dart';
import '../models/song.dart';
import '../presenters/ranking_presenter.dart';
import '../services/music_service.dart';
import '../widgets/cover_placeholder.dart';

/// Màn hình Bảng xếp hạng các bài hát được nghe nhiều nhất.
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> implements RankingView {
  late final RankingPresenter _presenter;
  List<Song> _songs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _presenter = RankingPresenter(this);
    MusicService.changeNotifier.addListener(_onDataChanged);
    _presenter.loadRanking();
  }

  @override
  void dispose() {
    MusicService.changeNotifier.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) _presenter.loadRanking();
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
  void showRanking(List<Song> songs) {
    if (mounted) setState(() => _songs = songs);
  }

  @override
  void showError(String message) {
    if (mounted) {
      setState(() => _error = message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700); // Vàng Gold
    if (rank == 2) return const Color(0xFFC0C0C0); // Bạc Silver
    if (rank == 3) return const Color(0xFFCD7F32); // Đồng Bronze
    return Colors.white54;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng xếp hạng Hot'),
        actions: [
          IconButton(
            onPressed: () => _presenter.loadRanking(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _songs.isEmpty
                  ? const Center(child: Text('Chưa có dữ liệu bảng xếp hạng'))
                  : RefreshIndicator(
                      onRefresh: () => _presenter.loadRanking(),
                      child: ListView.separated(
                        itemCount: _songs.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 72),
                        itemBuilder: (_, i) {
                          final s = _songs[i];
                          final rank = i + 1;
                          final isTop3 = rank <= 3;

                          return ListTile(
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 28,
                                  child: Text(
                                    '$rank',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isTop3 ? 18 : 14,
                                      color: _getRankColor(rank),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: s.coverImageUrl != null &&
                                          s.coverImageUrl!.isNotEmpty
                                      ? Image.network(
                                          s.coverImageUrl!,
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const CoverPlaceholder(size: 48),
                                        )
                                      : const CoverPlaceholder(size: 48),
                                ),
                              ],
                            ),
                            title: Text(
                              s.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${s.artist} • ${s.musicLength}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              '${s.luotNghe} lượt nghe',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                            onTap: () => _presenter.playSong(s, _songs),
                          );
                        },
                      ),
                    ),
    );
  }
}

// Alias tương thích
typedef RankingPage = RankingScreen;
