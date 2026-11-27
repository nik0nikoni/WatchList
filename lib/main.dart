import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'data/auth_api.dart';
import 'data/mock_watch_entry_repository.dart';
import 'data/token_store.dart';
import 'models/library_model.dart';
import 'router.dart';
import 'theme.dart';

// Сервер на ноутбуке: эмулятор Android не знает «localhost» — для него это
// 10.0.2.2; на десктопе и в браузере — localhost; на телефоне — IP ноутбука
final apiBase = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
    ? 'http://10.0.2.2:8080'
    : 'http://localhost:8080';

// Корень композиции: ЗДЕСЬ (и только здесь) выбирается источник данных
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // prefs до runApp (C9)
  final tokens = TokenStore();
  final loggedIn = await tokens.read() != null; // запуск решает по token-у

  router = GoRouter(
    initialLocation: loggedIn ? '/home' : '/login',
    routes: appRoutes,
  );

  final repository = MockWatchEntryRepository(); // на L5: вариант http — и всё

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthApi>(create: (_) => AuthApi(apiBase, tokens)),
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
