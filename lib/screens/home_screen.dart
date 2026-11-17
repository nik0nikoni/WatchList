import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/watch_entry.dart';
import '../models/library_model.dart';
import '../widgets/continue_card.dart';
import '../widgets/error_view.dart';
import '../widgets/stat_tile.dart';
import '../widgets/title_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget _buildContent(BuildContext context, LibraryModel model) {
    final theme = Theme.of(context);
    final entries = model.entries;
    final watching = model
        .withStatus(WatchStatus.watching)
        .where((e) => e.media.episodes > 1)
        .toList();
    final recent = entries.reversed.take(3).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text('Что смотрим сегодня?', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatTile(
                icon: Icons.video_library_outlined,
                value: '${entries.length}',
                label: 'Всего',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                icon: Icons.check_circle_outline,
                value: '${model.countWithStatus(WatchStatus.completed)}',
                label: 'Просмотрено',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                icon: Icons.bookmark_border,
                value: '${model.countWithStatus(WatchStatus.planned)}',
                label: 'В планах',
              ),
            ),
          ],
        ),
        if (watching.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Продолжить просмотр', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: watching.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) => ContinueCard(
                key: ValueKey(watching[index].id),
                entry: watching[index],
                onTap: () => context.push('/home/${watching[index].id}'),
              ),
            ),
          ),
        ],
        if (recent.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Недавно добавлено', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          for (final entry in recent) ...[
            TitleCard(
              key: ValueKey(entry.id),
              entry: entry,
              onTap: () => context.push('/home/${entry.id}'),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ],
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
      body = _buildContent(context, model);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('WatchList'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: body,
    );
  }
}
