import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'data/api_base.dart';
import 'data/auth_api.dart';
import 'data/file_api.dart';
import 'data/http_watch_entry_repository.dart';
import 'data/token_store.dart';
import 'models/library_model.dart';
import 'router.dart';
import 'theme.dart';

// Корень композиции: ЗДЕСЬ (и только здесь) выбирается источник данных
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // prefs до runApp (C9)
  final tokens = TokenStore();
  final loggedIn = await tokens.read() != null; // запуск решает по token-у

  router = GoRouter(
    initialLocation: loggedIn ? '/home' : '/login',
    routes: appRoutes,
  );

  // mock умер: источник данных — свой backend. Единственная строка выбора
  final repository = HttpWatchEntryRepository(
    apiBase,
    tokens,
    onUnauthorized: () => router.go('/login'), // 401 → login, в одном месте
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthApi>(create: (_) => AuthApi(apiBase, tokens)),
        Provider<FileApi>(
          create: (_) => FileApi(
            apiBase,
            tokens,
            onUnauthorized: () => router.go('/login'),
          ),
        ),
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
