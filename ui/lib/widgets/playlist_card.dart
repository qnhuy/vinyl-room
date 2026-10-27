import 'package:flutter/material.dart';
import '../models/playlist.dart';

/// Widget thẻ Playlist dùng cho Trang chủ, Cá nhân và Playlist công khai.
class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;
  final double width;

  const PlaylistCard({
    super.key,
    required this.playlist,
    required this.onTap,
    this.width = 140,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.queue_music, size: 36),
            const Spacer(),
            Text(
              playlist.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text('${playlist.songCount} bài'),
          ],
        ),
      ),
    );
  }
}
