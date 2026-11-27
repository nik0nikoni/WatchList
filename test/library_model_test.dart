import 'package:flutter_test/flutter_test.dart';
import 'package:watch_list/data/watch_entry.dart';
import 'package:watch_list/models/library_model.dart';

import 'fake_watch_entry_repository.dart';

// Модель — чистый Dart: тестируется без единого widget-а
void main() {
  late FakeWatchEntryRepository repository;
  late LibraryModel model;

  setUp(() {
    repository = FakeWatchEntryRepository();
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

  test('мутация при аварии возвращает сообщение и не трогает состояние', () async {
    await model.load();
    final entry = model.entries.first;
    repository.simulateError = true;

    expect(await model.remove(entry.id), isNotNull);
    expect(model.byId(entry.id), isNotNull);
  });

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

  // --- L5: поиск и ломти ---

  List<WatchEntry> many(int n) => [
    for (var i = 1; i <= n; i++)
      WatchEntry(
        id: i,
        media: MediaTitle(
          name: i.isEven ? 'Сериал $i' : 'Фильм $i',
          type: TitleType.movie,
          year: 2000,
          genres: '',
          description: '',
          episodes: 1,
        ),
        status: WatchStatus.planned,
      ),
  ];

  test('loadMore приклеивает следующий ломоть, пока страница полная', () async {
    repository = FakeWatchEntryRepository(seed: many(25));
    model = LibraryModel(repository);

    await model.load();
    expect(model.entries.length, 20);
    expect(model.hasMore, isTrue);

    await model.loadMore();
    expect(model.entries.length, 25);
    expect(model.hasMore, isFalse);
  });

  test('loadMore с guard-ом: параллельные вызовы — один запрос', () async {
    repository = FakeWatchEntryRepository(seed: many(25));
    model = LibraryModel(repository);
    await model.load();
    final before = repository.fetchCalls;

    await Future.wait([model.loadMore(), model.loadMore(), model.loadMore()]);

    expect(repository.fetchCalls, before + 1);
    expect(model.entries.length, 25); // без дублированных страниц
  });

  test('search идёт в хранилище, retry сохраняет фильтр', () async {
    repository = FakeWatchEntryRepository(seed: many(25));
    model = LibraryModel(repository);

    await model.load(search: 'сериал');
    expect(model.entries.length, 12);
    expect(model.entries.every((e) => e.media.name.startsWith('Сериал')), isTrue);

    await model.load(); // «Повторить»
    expect(model.search, 'сериал');
    expect(model.entries.length, 12);

    await model.load(search: ''); // сброс
    expect(model.entries.length, 20);
  });

  test('ошибка догрузки: загруженное остаётся, retryMore догружает', () async {
    repository = FakeWatchEntryRepository(seed: many(25));
    model = LibraryModel(repository);
    await model.load();

    repository.simulateError = true;
    await model.loadMore();
    expect(model.loadMoreError, isNotNull);
    expect(model.entries.length, 20);

    repository.simulateError = false;
    await model.retryMore();
    expect(model.loadMoreError, isNull);
    expect(model.entries.length, 25);
  });
}
