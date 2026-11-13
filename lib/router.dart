import 'package:go_router/go_router.dart';
import 'screens/add_entry_screen.dart';
import 'screens/details_screen.dart';
import 'screens/home_screen.dart';
import 'screens/library_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/status_lists_screen.dart';

final router = GoRouter(
  initialLocation: '/login', // приложение стартует с аутентификации
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/library',
      builder: (context, state) => const LibraryScreen(),
    ),
    GoRoute(
      path: '/library/new', // ФИКСИРОВАННЫЙ сегмент — строго перед ':id'
      builder: (context, state) => const AddEntryScreen(),
    ),
    GoRoute(
      path: '/library/:id', // переменный сегмент: /library/3, /library/7
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return DetailsScreen(id: id);
      },
    ),
    GoRoute(
      path: '/library/:id/edit', // та же форма, но для существующей записи
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return AddEntryScreen(id: id);
      },
    ),
    GoRoute(
      path: '/lists',
      builder: (context, state) => const StatusListsScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);
