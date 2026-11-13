import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../widgets/stat_tile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final completed =
        mockEntries.where((e) => e.status == WatchStatus.completed).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: scheme.primaryContainer,
              child: Text(
                'А',
                style: theme.textTheme.headlineMedium
                    ?.copyWith(color: scheme.onPrimaryContainer),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Abobus',
              style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
          Text(
            'abobus@example.com',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  icon: Icons.video_library_outlined,
                  value: '${mockEntries.length}',
                  label: 'Тайтлов',
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
              const Expanded(
                child: StatTile(
                  icon: Icons.star_outline_rounded,
                  value: '8.7',
                  label: 'Ср. оценка',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_none),
                  title: const Text('Уведомления'),
                  trailing: Switch(value: true, onChanged: (_) {}),
                ),
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Тёмная тема'),
                  trailing: Switch(value: true, onChanged: (_) {}),
                ),
                const ListTile(
                  leading: Icon(Icons.language),
                  title: Text('Язык'),
                  trailing: Text('Русский'),
                ),
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('О приложении'),
                  trailing: Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.logout),
            label: const Text('Выйти из аккаунта'),
          ),
        ],
      ),
    );
  }
}