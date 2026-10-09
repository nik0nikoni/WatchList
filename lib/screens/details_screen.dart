import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../widgets/info_row.dart';
import '../widgets/poster_placeholder.dart';

class DetailsScreen extends StatelessWidget {
  final WatchEntry entry;

  const DetailsScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final media = entry.media;
    final genres = media.genres.split(', ');
    final rating = entry.myRating;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.favorite_border)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.share_outlined)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Center(
            child: PosterPlaceholder(
              type: media.type,
              width: 160,
              height: 230,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            media.name,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${media.type.label} · ${media.year}',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: genres.map((g) => Chip(label: Text(g))).toList(),
          ),
          const SizedBox(height: 20),
          DropdownMenu<WatchStatus>(
            expandedInsets: EdgeInsets.zero,
            label: const Text('Статус'),
            initialSelection: entry.status,
            dropdownMenuEntries: WatchStatus.values
                .map((s) => DropdownMenuEntry(value: s, label: s.label))
                .toList(),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Моя оценка', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (var i = 1; i <= 10; i++)
                        Icon(
                          rating != null && i <= rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 24,
                          color: scheme.primary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Прогресс', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: entry.watchedEpisodes / media.episodes,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${entry.watchedEpisodes} / ${media.episodes} эп.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Описание', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(media.description, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 20),
          Text('Информация', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          InfoRow(label: 'Тип', value: media.type.label),
          InfoRow(label: 'Год выхода', value: '${media.year}'),
          InfoRow(label: 'Эпизодов', value: '${media.episodes}'),
          InfoRow(label: 'Жанры', value: media.genres),
          if (entry.note.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Моя заметка', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(entry.note),
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Редактировать запись'),
          ),
        ],
      ),
    );
  }
}