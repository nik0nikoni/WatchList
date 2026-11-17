import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:watch_list/data/mock_watch_entry_repository.dart';
import 'package:watch_list/main.dart';
import 'package:watch_list/models/library_model.dart';

void main() {
  testWidgets('вход → главная: spinner, затем данные из хранилища', (
    tester,
  ) async {
    final repository = MockWatchEntryRepository();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<MockWatchEntryRepository>.value(value: repository),
          ChangeNotifierProvider(
            create: (_) => LibraryModel(repository)..load(),
          ),
        ],
        child: const MyApp(),
      ),
    );

    // неверные данные — ошибки валидации, вход не происходит
    await tester.tap(find.text('Войти'));
    await tester.pump();
    expect(find.text('Введите e-mail'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'ana@utm.md');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
    await tester.tap(find.text('Войти'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Что смотрим сегодня?'), findsOneWidget);
  });
}
