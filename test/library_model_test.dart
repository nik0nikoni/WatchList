import 'package:flutter_test/flutter_test.dart';
import 'package:watch_list/data/mock_watch_entry_repository.dart';
import 'package:watch_list/data/watch_entry.dart';
import 'package:watch_list/models/library_model.dart';

// Модель — чистый Dart: тестируется без единого widget-а
void main() {
  late MockWatchEntryRepository repository;
  late LibraryModel model;

  setUp(() {
    repository = MockWatchEntryRepository(latency: Duration.zero);
    model = LibraryModel(repository);
  });

  test('load: грузится → данные', () async {
    final future = model.load();
    expect(model.isLoading, isTrue);
    await future;
    expect(model.isLoading, isFalse);
    expect(model.error, isNull);
    expect(model.entries, isNotEmpty);
  });

  test('load при аварии: ошибка, данные не появляются', () async {
    repository.simulateError = true;
    await model.load();
    expect(model.error, isNotNull);
    expect(model.entries, isEmpty);
  });

  test('entries наружу — только для чтения', () async {
    await model.load();
    expect(() => model.entries.removeLast(), throwsUnsupportedError);
  });

  test('add: id даёт хранилище, подписчики извещены', () async {
    await model.load();
    final before = model.entries.length;
    var notified = 0;
    model.addListener(() => notified++);

    final error = await model.add(model.entries.first.copyWith(id: 0));

    expect(error, isNull);
    expect(model.entries.length, before + 1);
    expect(model.entries.last.id, isNot(0));
    expect(notified, 1);
  });

  test('remove: запись исчезает', () async {
    await model.load();
    final id = model.entries.first.id;
    expect(await model.remove(id), isNull);
    expect(model.byId(id), isNull);
  });

  test(
    'мутация при аварии возвращает сообщение и не трогает состояние',
    () async {
      await model.load();
      final entry = model.entries.first;
      repository.simulateError = true;

      expect(await model.remove(entry.id), isNotNull);
      expect(model.byId(entry.id), isNotNull);
    },
  );

  test('setStatus «Просмотрено» отмечает все эпизоды', () async {
    await model.load();
    final entry = model.entries.firstWhere(
      (e) => e.status == WatchStatus.watching,
    );
    await model.setStatus(entry, WatchStatus.completed);
    final updated = model.byId(entry.id)!;
    expect(updated.status, WatchStatus.completed);
    expect(updated.watchedEpisodes, entry.media.episodes);
  });
}
