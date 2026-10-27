import 'package:flutter/material.dart';
import '../models/song.dart';
import 'cover_placeholder.dart';

/// Widget hàng bài hát trong danh sách (dùng cho Ranking, Playlist, Yêu thích, Tìm kiếm).
class SongTile extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  final Widget? leading;
  final Widget? trailing;

  const SongTile({
    super.key,
    required this.song,
    required this.onTap,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: leading ??
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: song.coverImageUrl != null && song.coverImageUrl!.isNotEmpty
                ? Image.network(
                    song.coverImageUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const CoverPlaceholder(size: 50),
                  )
                : const CoverPlaceholder(size: 50),
          ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${song.artist} • ${song.musicLength}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing,
    );
  }
}
