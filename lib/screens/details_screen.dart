import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/watch_entry.dart';
import '../models/library_model.dart';
import '../widgets/error_view.dart';
import '../widgets/info_row.dart';
import '../widgets/poster_placeholder.dart';

class DetailsScreen extends StatelessWidget {
  final int id;

  const DetailsScreen({super.key, required this.id});

  void _notify(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // деструктивное действие → блокирующее решение через AlertDialog
  Future<void> _delete(BuildContext context, WatchEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: const Text('Удалить запись?'),
        content: Text('«${entry.media.name}» исчезнет из вашей библиотеки.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    // ok == true, а не ok!: закрытый тапом мимо диалог возвращает null
    if (ok != true || !context.mounted) return;
    final error = await context.read<LibraryModel>().remove(entry.id);
    if (!context.mounted) return; // экран может умереть, пока «запрос» летит
    if (error != null) {
      _notify(context, error);
      return;
    }
    _notify(context, 'Удалено: ${entry.media.name}');
    context.pop(); // записи больше нет — её экран уходит из стека
  }

  Future<void> _toggleFavorite(BuildContext context, WatchEntry entry) async {
    final error = await context.read<LibraryModel>().toggleFavorite(entry);
    if (!context.mounted) return;
    _notify(
      context,
      error ??
          (entry.isFavorite ? 'Убрано из избранного' : 'Добавлено в избранное'),
    );
  }

  Future<void> _setStatus(
    BuildContext context,
    WatchEntry entry,
    WatchStatus status,
  ) async {
    final error = await context.read<LibraryModel>().setStatus(entry, status);
    if (!context.mounted) return;
    _notify(context, error ?? 'Статус: ${status.label}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // экран сам ищет свою запись по id — теперь через модель; у null два
    // смысла: список ещё грузится или записи с таким id нет
    final model = context.watch<LibraryModel>();
    final entry = model.byId(id);
    if (entry == null) {
      final Widget body;
      if (model.isLoading) {
        body = const Center(child: CircularProgressIndicator());
      } else if (model.error != null) {
        body = ErrorView(
          message: model.error!,
          onRetry: () => context.read<LibraryModel>().load(),
        );
      } else {
        body = Center(child: Text('Запись #$id не существует'));
      }
      return Scaffold(appBar: AppBar(), body: body);
    }
    final media = entry.media;
    final genres = media.genres
        .split(',')
        .map((g) => g.trim())
        .where((g) => g.isNotEmpty)
        .toList();
    final rating = entry.myRating;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () => _toggleFavorite(context, entry),
            icon: Icon(
              entry.isFavorite ? Icons.favorite : Icons.favorite_border,
            ),
          ),
          IconButton(
            onPressed: () => _notify(context, 'Ссылка скопирована'),
            icon: const Icon(Icons.share_outlined),
          ),
          IconButton(
            onPressed: () => _delete(context, entry),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Center(
            child: PosterPlaceholder(
              type: media.type,
              name: media.name,
              posterUrl: entry.posterUrl,
              width: 160,
              height: 230,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            media.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${media.type.label} · ${media.year}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
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
          Text('Статус', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          // выбранный чип — всегда статус из модели: при ошибке ничего не «залипает»
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: WatchStatus.values
                .map(
                  (s) => ChoiceChip(
                    label: Text(s.label),
                    selected: entry.status == s,
                    onSelected: entry.status == s
                        ? null
                        : (_) => _setStatus(context, entry, s),
                  ),
                )
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
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (media.description.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Описание', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(media.description, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 20),
          Text('Информация', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          InfoRow(label: 'Тип', value: media.type.label),
          InfoRow(label: 'Год выхода', value: '${media.year}'),
          InfoRow(label: 'Эпизодов', value: '${media.episodes}'),
          if (genres.isNotEmpty) InfoRow(label: 'Жанры', value: media.genres),
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
            // адрес текущей вкладки + /edit: /home/3/edit, /library/3/edit...
            onPressed: () => context.push(
              '${GoRouterState.of(context).matchedLocation}/edit',
            ),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Редактировать запись'),
          ),
        ],
      ),
    );
  }
}
