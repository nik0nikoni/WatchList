import 'package:go_router/go_router.dart';
import 'screens/add_entry_screen.dart';
import 'screens/details_screen.dart';
import 'screens/home_screen.dart';
import 'screens/library_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/status_lists_screen.dart';
import 'widgets/app_shell.dart';

// Детали записи и её редактирование — под-маршруты вкладки, из которой их
// открыли: /home/3, /library/3/edit, /lists/3... Так панель вкладок остаётся
// видимой, а «назад» возвращает в тот же список.
GoRoute _entryRoute() => GoRoute(
      path: ':id', // переменный сегмент; пути под-маршрутов — без '/' в начале
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return DetailsScreen(id: id);
      },
      routes: [
        GoRoute(
          path: 'edit', // полный адрес: <вкладка>/:id/edit
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return AddEntryScreen(id: id);
          },
        ),
      ],
    );

final router = GoRouter(
  initialLocation: '/login', // приложение стартует с аутентификации
  routes: [
    GoRoute(
      path: '/login', // ВНЕ shell-а: у login нет панели вкладок
      builder: (context, state) => const LoginScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
            routes: [_entryRoute()],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/library',
            builder: (context, state) => const LibraryScreen(),
            routes: [
              GoRoute(
                path: 'new', // ФИКСИРОВАННЫЙ сегмент — строго перед ':id'
                builder: (context, state) => const AddEntryScreen(),
              ),
              _entryRoute(),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/lists',
            builder: (context, state) => const StatusListsScreen(),
            routes: [_entryRoute()],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ]),
      ],
    ),
  ],
);
