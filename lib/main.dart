import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/mock_watch_entry_repository.dart';
import 'models/library_model.dart';
import 'router.dart';
import 'theme.dart';

// Корень композиции: ЗДЕСЬ (и только здесь) выбирается источник данных
void main() {
  final repository = MockWatchEntryRepository(); // на L5: вариант http — и всё

  runApp(
    MultiProvider(
      providers: [
        // леса демонстрации аварии (переключатель в профиле) — уйдут на L5
        Provider<MockWatchEntryRepository>.value(value: repository),
        ChangeNotifierProvider(
          create: (_) => LibraryModel(repository)..load(), // DI + старт
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'WatchList',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}
