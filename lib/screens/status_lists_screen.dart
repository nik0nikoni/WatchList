import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/watch_entry.dart';
import '../models/library_model.dart';
import '../widgets/error_view.dart';
import '../widgets/title_card.dart';

class StatusListsScreen extends StatelessWidget {
  const StatusListsScreen({super.key});

  Widget _buildList(BuildContext context, List<WatchEntry> items) {
    if (items.isEmpty) {
      return const Center(child: Text('В этом списке пока пусто'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => TitleCard(
        key: ValueKey(items[index].id),
        entry: items[index],
        onTap: () => context.push('/lists/${items[index].id}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<LibraryModel>();

    final Widget body;
    if (model.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (model.error != null) {
      body = ErrorView(
        message: model.error!,
        onRetry: () => context.read<LibraryModel>().load(),
      );
    } else {
      body = TabBarView(
        children: WatchStatus.values
            .map((status) => _buildList(context, model.withStatus(status)))
            .toList(),
      );
    }

    return DefaultTabController(
      length: WatchStatus.values.length,
      initialIndex: 1, // «Смотрю»
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Мои списки'),
          bottom: TabBar(
            isScrollable: true,
            tabs: WatchStatus.values
                .map(
                  (status) => Tab(
                    text: model.isLoading || model.error != null
                        ? status.label
                        : '${status.label} · ${model.countWithStatus(status)}',
                  ),
                )
                .toList(),
          ),
        ),
        body: body,
      ),
    );
  }
}
