import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/mock_data.dart';
import '../widgets/continue_card.dart';
import '../widgets/nav_tile.dart';
import '../widgets/stat_tile.dart';
import '../widgets/title_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final watching = mockEntries
        .where((e) => e.status == WatchStatus.watching && e.media.episodes > 1)
        .toList();
    final completed =
        mockEntries.where((e) => e.status == WatchStatus.completed).length;
    final planned =
        mockEntries.where((e) => e.status == WatchStatus.planned).length;
    final recent = mockEntries.reversed.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('WatchList'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          IconButton(
              onPressed: () {}, icon: const Icon(Icons.notifications_none)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text('Что смотрим сегодня?', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  icon: Icons.video_library_outlined,
                  value: '${mockEntries.length}',
                  label: 'Всего',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  icon: Icons.check_circle_outline,
                  value: '$completed',
                  label: 'Просмотрено',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  icon: Icons.bookmark_border,
                  value: '$planned',
                  label: 'В планах',
                ),
              ),
            ],
          ),
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
                entry: watching[index],
                onTap: () => context.push('/library/${watching[index].id}'),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Разделы', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              NavTile(
                icon: Icons.video_library_outlined,
                label: 'Библиотека',
                onTap: () => context.go('/library'),
              ),
              NavTile(
                icon: Icons.checklist_rounded,
                label: 'Мои списки',
                onTap: () => context.go('/lists'),
              ),
              NavTile(
                icon: Icons.add_circle_outline,
                label: 'Добавить',
                onTap: () => context.push('/library/new'),
              ),
              NavTile(
                icon: Icons.person_outline,
                label: 'Профиль',
                onTap: () => context.go('/profile'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Недавно добавлено', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          for (final entry in recent) ...[
            TitleCard(
              entry: entry,
              onTap: () => context.push('/library/${entry.id}'),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}