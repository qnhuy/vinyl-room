import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../providers/player_provider.dart';
import 'cover_placeholder.dart';

/// Widget thanh phát nhạc thu nhỏ hiển thị ở đáy màn hình.
class MiniPlayer extends StatelessWidget {
  final VoidCallback? onTap;

  const MiniPlayer({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: PlayerProvider.instance.playerChangeNotifier,
      builder: (context, _, __) {
        final song = PlayerProvider.instance.current;
        if (song == null) return const SizedBox.shrink();

        return StreamBuilder<PlayerState>(
          stream: PlayerProvider.instance.playerStateStream,
          builder: (context, snapshot) {
            final playing =
                snapshot.data?.playing ?? PlayerProvider.instance.playing;

            return GestureDetector(
              onTap: onTap,
              child: Container(
                height: 64,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: song.coverImageUrl != null &&
                              song.coverImageUrl!.isNotEmpty
                          ? Image.network(
                              song.coverImageUrl!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const CoverPlaceholder(size: 48),
                            )
                          : const CoverPlaceholder(size: 48),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      onPressed: () => PlayerProvider.instance.previous(),
                    ),
                    IconButton(
                      icon: Icon(
                        playing
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        size: 36,
                      ),
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: () => PlayerProvider.instance.togglePlay(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      onPressed: () => PlayerProvider.instance.next(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
