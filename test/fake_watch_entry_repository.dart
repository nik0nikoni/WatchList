import 'package:watch_list/data/result.dart';
import 'package:watch_list/data/watch_entry.dart';
import 'package:watch_list/data/watch_entry_repository.dart';

// Тестовый дублёр интерфейса L4: mock из приложения умер на L5, но модели
// и сквозному тесту по-прежнему нужен источник без сети — живёт в test/
class FakeWatchEntryRepository implements WatchEntryRepository {
  FakeWatchEntryRepository({this.latency = Duration.zero});

  final Duration latency;
  final List<WatchEntry> _entries = List.of(_seed);
  int _nextId = 1000;
  bool simulateError = false; // авария: включена → любой вызов проваливается

  static const _errNetwork = 'Нет сети — повторите попытку';
  static const _errNotFound = 'Запись не существует';

  Future<bool> _fails() async {
    await Future.delayed(latency);
    return simulateError;
  }

  @override
  Future<Result<List<WatchEntry>>> fetchAll() async {
    if (await _fails()) return const Err(_errNetwork);
    return Ok(List.of(_entries));
  }

  @override
  Future<Result<WatchEntry>> fetchById(int id) async {
    if (await _fails()) return const Err(_errNetwork);
    final entry = _entries.where((e) => e.id == id).firstOrNull;
    return entry == null ? const Err(_errNotFound) : Ok(entry);
  }

  @override
  Future<Result<WatchEntry>> create(WatchEntry entry) async {
    if (await _fails()) return const Err(_errNetwork);
    final created = entry.copyWith(id: _nextId++);
    _entries.add(created);
    return Ok(created);
  }

  @override
  Future<Result<WatchEntry>> update(WatchEntry entry) async {
    if (await _fails()) return const Err(_errNetwork);
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index == -1) return const Err(_errNotFound);
    _entries[index] = entry;
    return Ok(entry);
  }

  @override
  Future<Result<void>> delete(int id) async {
    if (await _fails()) return const Err(_errNetwork);
    final index = _entries.indexWhere((e) => e.id == id);
    if (index == -1) return const Err(_errNotFound);
    _entries.removeAt(index);
    return const Ok(null);
  }
}

const _seed = [
  WatchEntry(
    id: 1,
    media: MediaTitle(
      name: 'Начало',
      type: TitleType.movie,
      year: 2010,
      genres: 'фантастика',
      description: '',
      episodes: 1,
    ),
    status: WatchStatus.completed,
    myRating: 9,
    watchedEpisodes: 1,
  ),
  WatchEntry(
    id: 2,
    media: MediaTitle(
      name: 'Во все тяжкие',
      type: TitleType.series,
      year: 2008,
      genres: 'драма',
      description: '',
      episodes: 62,
    ),
    status: WatchStatus.watching,
    myRating: 10,
    watchedEpisodes: 41,
  ),
  WatchEntry(
    id: 3,
    media: MediaTitle(
      name: 'Атака титанов',
      type: TitleType.anime,
      year: 2013,
      genres: 'экшен',
      description: '',
      episodes: 87,
    ),
    status: WatchStatus.planned,
  ),
];
