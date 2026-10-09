import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import 'poster_placeholder.dart';

class ContinueCard extends StatelessWidget {
  final WatchEntry entry;
  final VoidCallback? onTap;

  const ContinueCard({super.key, required this.entry, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = entry.media;

    return SizedBox(
      width: 140,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PosterPlaceholder(type: media.type, width: 140, height: 100),
            const SizedBox(height: 8),
            Text(
              media.name,
              style: theme.textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: entry.watchedEpisodes / media.episodes,
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${entry.watchedEpisodes} / ${media.episodes} эп.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}