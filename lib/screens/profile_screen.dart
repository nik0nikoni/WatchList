import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/mock_watch_entry_repository.dart';
import '../data/watch_entry.dart';
import '../models/library_model.dart';
import '../widgets/error_view.dart';
import '../widgets/stat_tile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // эфемерное состояние переключателя → setState, а не Provider
  bool _simulateError = false;

  @override
  void initState() {
    super.initState();
    // read, а не watch: одно чтение при создании, подписка не нужна
    _simulateError = context.read<MockWatchEntryRepository>().simulateError;
  }

  // леса демонстрации: единственное место UI, которое знает о mock-е —
  // уйдёт на L5 вместе с ним
  void _setSimulateError(bool value) {
    context.read<MockWatchEntryRepository>().simulateError = value;
    setState(() => _simulateError = value);
  }

  Widget _buildStats(LibraryModel model) {
    if (model.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (model.error != null) {
      return ErrorView(
        message: model.error!,
        onRetry: () => context.read<LibraryModel>().load(),
      );
    }
    final average = model.averageRating;
    return Row(
      children: [
        Expanded(
          child: StatTile(
            icon: Icons.video_library_outlined,
            value: '${model.entries.length}',
            label: 'Тайтлов',
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
            icon: Icons.star_outline_rounded,
            value: average == null ? '—' : average.toStringAsFixed(1),
            label: 'Ср. оценка',
          ),
        ),
      ],
    );
  }

  // блокирующее решение → AlertDialog с результатом
  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text('Чтобы вернуться, придётся войти заново.'),
        actions: [
          // dialogCtx, а не context: под вложенными навигаторами shell-а
          // pop на context-е экрана закрыл бы не диалог, а что-то другое
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Нет'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Да, выйти'),
          ),
        ],
      ),
    );
    // после await context используется только если экран ещё жив
    if (ok == true && context.mounted) {
      context.go('/login'); // go: раздел с вкладками уходит из стека
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final model = context.watch<LibraryModel>();

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
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Abobus',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          Text(
            'abobus@example.com',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _buildStats(model),
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
                SwitchListTile(
                  secondary: const Icon(Icons.cloud_off_outlined),
                  title: const Text('Симулировать сбой сети'),
                  subtitle: const Text('Демонстрация экрана ошибки'),
                  value: _simulateError,
                  onChanged: _setSimulateError,
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
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Выйти из аккаунта'),
          ),
        ],
      ),
    );
  }
}
