import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import 'poster_placeholder.dart';
import 'status_badge.dart';

class TitleCard extends StatelessWidget {
  final WatchEntry entry;
  final VoidCallback? onTap;

  const TitleCard({super.key, required this.entry, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final media = entry.media;
    final subtle = theme.textTheme.bodySmall
        ?.copyWith(color: scheme.onSurfaceVariant);
    final showProgress = media.episodes > 1 &&
        (entry.status == WatchStatus.watching ||
            entry.status == WatchStatus.onHold ||
            entry.status == WatchStatus.dropped);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PosterPlaceholder(type: media.type),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      media.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text('${media.type.label} · ${media.year}', style: subtle),
                    Text(
                      media.genres,
                      style: subtle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (showProgress) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: entry.watchedEpisodes / media.episodes,
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${entry.watchedEpisodes} / ${media.episodes} эп.',
                        style: subtle,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        StatusBadge(status: entry.status),
                        const Spacer(),
                        if (entry.myRating != null) ...[
                          Icon(Icons.star_rounded,
                              size: 18, color: scheme.primary),
                          const SizedBox(width: 2),
                          Text('${entry.myRating}',
                              style: theme.textTheme.labelLarge),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}