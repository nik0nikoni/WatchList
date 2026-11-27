import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:watch_list/data/auth_api.dart';
import 'package:watch_list/data/mock_watch_entry_repository.dart';
import 'package:watch_list/data/result.dart';
import 'package:watch_list/data/token_store.dart';
import 'package:watch_list/main.dart';
import 'package:watch_list/models/library_model.dart';
import 'package:watch_list/router.dart';

// В тестах сети нет: вход подменяется — пароль 'secret1' верный, иной нет
class _FakeAuthApi extends AuthApi {
  _FakeAuthApi() : super('', TokenStore());

  @override
  Future<Result<void>> login(String email, String password) async =>
      password == 'secret1'
      ? const Ok(null)
      : const Err('Неверный email или пароль');
}

void main() {
  testWidgets('вход → главная: spinner, затем данные из хранилища', (
    tester,
  ) async {
    router = GoRouter(initialLocation: '/login', routes: appRoutes);
    final repository = MockWatchEntryRepository();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthApi>.value(value: _FakeAuthApi()),
          Provider<MockWatchEntryRepository>.value(value: repository),
          ChangeNotifierProvider(
            create: (_) => LibraryModel(repository)..load(),
          ),
        ],
        child: const MyApp(),
      ),
    );

    // неверные данные — ошибки валидации, запрос не уходит
    await tester.tap(find.text('Войти'));
    await tester.pump();
    expect(find.text('Введите e-mail'), findsOneWidget);

    // неверный пароль — переведённое сообщение в SnackBar, остаёмся на login
    await tester.enterText(find.byType(TextFormField).at(0), 'ana@utm.md');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong12');
    await tester.tap(find.text('Войти'));
    await tester.pump();
    expect(find.text('Неверный email или пароль'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
    await tester.tap(find.text('Войти'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Что смотрим сегодня?'), findsOneWidget);
  });
}
