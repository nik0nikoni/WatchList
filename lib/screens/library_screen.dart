import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../widgets/title_card.dart';
import 'details_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Моя библиотека')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              hintText: 'Поиск по названию',
              leading: Icon(Icons.search),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                FilterChip(label: const Text('Все'), selected: true, onSelected: (_) {}),
                const SizedBox(width: 8),
                FilterChip(label: const Text('Фильмы'), selected: false, onSelected: (_) {}),
                const SizedBox(width: 8),
                FilterChip(label: const Text('Сериалы'), selected: false, onSelected: (_) {}),
                const SizedBox(width: 8),
                FilterChip(label: const Text('Аниме'), selected: false, onSelected: (_) {}),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: mockEntries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) =>
                  TitleCard(entry: mockEntries[index]),
            ),
          ),
        ],
      ),
    );
  }
}