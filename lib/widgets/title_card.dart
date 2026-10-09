import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import 'status_badge.dart';

class TitleCard extends StatelessWidget {
  final WatchEntry entry;
  final VoidCallback? onTap;

  const TitleCard({super.key, required this.entry, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final media = entry.media;

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Text(
            media.name[0],
            style: TextStyle(color: scheme.onPrimaryContainer),
          ),
        ),
        title: Text(media.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${media.type.label} · ${media.year} · ${media.genres}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            StatusBadge(status: entry.status),
            if (entry.myRating != null) ...[
              const SizedBox(height: 4),
              Text(
                '★ ${entry.myRating}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ],
        ),
      ),
    );
  }
}