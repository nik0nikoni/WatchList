import 'package:flutter/material.dart';
import '../data/mock_data.dart';

class AddEntryScreen extends StatelessWidget {
  const AddEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Новая запись')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const TextField(
            decoration: InputDecoration(
              labelText: 'Название',
              hintText: 'Например, Cowboy Bebop',
              prefixIcon: Icon(Icons.movie_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Text('Тип', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<TitleType>(
            segments: TitleType.values
                .map((t) => ButtonSegment(value: t, label: Text(t.label)))
                .toList(),
            selected: const {TitleType.anime},
            onSelectionChanged: (_) {},
          ),
          const SizedBox(height: 20),
          DropdownMenu<WatchStatus>(
            expandedInsets: EdgeInsets.zero,
            label: const Text('Статус'),
            initialSelection: WatchStatus.planned,
            dropdownMenuEntries: WatchStatus.values
                .map((s) => DropdownMenuEntry(value: s, label: s.label))
                .toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Год выхода',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Эпизодов',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Жанры',
              hintText: 'экшен, драма',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownMenu<int>(
            expandedInsets: EdgeInsets.zero,
            label: const Text('Моя оценка'),
            leadingIcon: const Icon(Icons.star_rounded),
            dropdownMenuEntries: [
              for (var i = 10; i >= 1; i--)
                DropdownMenuEntry(value: i, label: '$i'),
            ],
          ),
          const SizedBox(height: 16),
          const TextField(
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Заметка',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Добавить в избранное'),
            value: false,
            onChanged: (_) {},
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {},
            child: const Text('Сохранить'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }
}