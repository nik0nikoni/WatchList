import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../widgets/title_card.dart';
import 'details_screen.dart';

class StatusListsScreen extends StatelessWidget {
  const StatusListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: WatchStatus.values.length,
      initialIndex: 1, // «Смотрю»
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Мои списки'),
          bottom: TabBar(
            isScrollable: true,
            tabs: WatchStatus.values
                .map((status) => Tab(text: status.label))
                .toList(),
          ),
        ),
        body: TabBarView(
          children: WatchStatus.values.map((status) {
            final items =
                mockEntries.where((e) => e.status == status).toList();
            if (items.isEmpty) {
              return const Center(child: Text('В этом списке пока пусто'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) => TitleCard(
                entry: items[index],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailsScreen(entry: items[index]),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}