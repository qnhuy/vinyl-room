import 'package:flutter/material.dart';
import '../models/song.dart';
import 'cover_placeholder.dart';

/// Widget thẻ bài hát dạng cuộn ngang.
class SongCard extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  final double size;

  const SongCard({
    super.key,
    required this.song,
    required this.onTap,
    this.size = 140,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: SizedBox(
        width: size,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: song.coverImageUrl != null && song.coverImageUrl!.isNotEmpty
                  ? Image.network(
                      song.coverImageUrl!,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => CoverPlaceholder(size: size),
                    )
                  : CoverPlaceholder(size: size),
            ),
            const SizedBox(height: 8),
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
