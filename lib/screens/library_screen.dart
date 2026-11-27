import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/watch_entry.dart';
import '../models/library_model.dart';
import '../widgets/error_view.dart';
import '../widgets/title_card.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  // эфемерное состояние экрана — setState, а не Provider:
  // его не читает никто, кроме этого экрана
  TitleType? _type; // null — «Все»
  bool _favoritesOnly = false;

  // L5: поиск по названию ушёл на сервер (LibraryModel.load(search:));
  // чипы типа и избранного фильтруют уже загруженные ломти
  List<WatchEntry> _filter(List<WatchEntry> entries) {
    return entries.where((e) {
      if (_type != null && e.media.type != _type) return false;
      if (_favoritesOnly && !e.isFavorite) return false;
      return true;
    }).toList();
  }

  // хвост списка: просит следующий ломоть и показывает маленький spinner;
  // read, а не watch — это действие, а не подписка
  Widget _buildTail(LibraryModel model) {
    if (model.loadMoreError != null) {
      return Column(
        children: [
          Text(model.loadMoreError!, textAlign: TextAlign.center),
          TextButton(
            onPressed: () => context.read<LibraryModel>().retryMore(),
            child: const Text('Повторить'),
          ),
        ],
      );
    }
    context.read<LibraryModel>().loadMore();
    return const Padding(
      padding: EdgeInsets.all(12),
      child: Center(
        child: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  // свайп → подтверждение → удаление через модель; false — карточка остаётся
  Future<bool> _confirmDelete(WatchEntry entry) async {
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
    if (ok != true || !mounted) return false;
    final error = await context.read<LibraryModel>().remove(entry.id);
    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Удалено: ${entry.media.name}')),
    );
    return error == null;
  }

  Widget _typeChip(String label, TitleType? type) => FilterChip(
    label: Text(label),
    selected: _type == type,
    onSelected: (_) => setState(() => _type = type),
  );

  Widget _buildList(LibraryModel model) {
    final visible = _filter(model.entries);
    if (visible.isEmpty && !model.hasMore) {
      return const Center(child: Text('Ничего не найдено'));
    }
    final hasTail = model.hasMore || model.loadMoreError != null;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: visible.length + (hasTail ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == visible.length) return _buildTail(model);
        final entry = visible[index];
        return Dismissible(
          key: ValueKey(entry.id), // идентичность из данных, не UniqueKey
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) => _confirmDelete(entry),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
          child: TitleCard(
            entry: entry,
            onTap: () => context.push('/library/${entry.id}'),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<LibraryModel>(); // watch в build

    final Widget body;
    if (model.isLoading) {
      body = const Center(child: CircularProgressIndicator()); // 1) грузится
    } else if (model.error != null) {
      body = ErrorView(
        message: model.error!, // 2) упало
        onRetry: () => context.read<LibraryModel>().load(), // read: действие
      );
    } else {
      body = _buildList(model); // 3) данные
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Моя библиотека'),
        actions: [
          // один живой угол: счётчик избранного перерисовывается сам
          Consumer<LibraryModel>(
            builder: (context, library, child) => IconButton(
              tooltip: 'Только избранное',
              onPressed: () => setState(() => _favoritesOnly = !_favoritesOnly),
              icon: Badge(
                label: Text('${library.favoritesCount}'),
                isLabelVisible: library.favoritesCount > 0,
                child: child,
              ),
            ),
            // child не зависит от модели — при её изменениях не пересобирается
            child: Icon(
              _favoritesOnly ? Icons.favorite : Icons.favorite_border,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/library/new'),
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              hintText: 'Поиск по названию или жанру',
              leading: const Icon(Icons.search),
              // Enter → запрос на сервер; пустая строка сбрасывает поиск
              onSubmitted: (q) =>
                  context.read<LibraryModel>().load(search: q.trim()),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _typeChip('Все', null),
                const SizedBox(width: 8),
                _typeChip('Фильмы', TitleType.movie),
                const SizedBox(width: 8),
                _typeChip('Сериалы', TitleType.series),
                const SizedBox(width: 8),
                _typeChip('Аниме', TitleType.anime),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
