import 'mock_data.dart';
import 'result.dart';
import 'watch_entry.dart';
import 'watch_entry_repository.dart';

// Хранилище в памяти, с повадками сети: задержка и переключаемая авария.
// Единственный клиент mock_data.dart — на L5 оба файла уходят
class MockWatchEntryRepository implements WatchEntryRepository {
  MockWatchEntryRepository({this.latency = const Duration(milliseconds: 800)});

  final Duration latency; // в тестах — Duration.zero
  final List<WatchEntry> _entries = List.of(mockEntries); // seed из L2
  int _nextId = 1000; // выше любого id из seed-а
  bool simulateError = false; // авария: включена → любой вызов проваливается

  static const _errNetwork = 'Сервер не отвечает — повторите попытку';
  static const _errNotFound = 'Запись не существует';

  // общий пролог каждого метода: сеть не отвечает мгновенно и иногда падает
  Future<bool> _networkFails() async {
    await Future.delayed(latency);
    return simulateError;
  }

  @override
  Future<Result<List<WatchEntry>>> fetchAll() async {
    if (await _networkFails()) return const Err(_errNetwork);
    return Ok(List.of(_entries)); // копия — внутренность не отдаётся из рук
  }

  @override
  Future<Result<WatchEntry>> fetchById(int id) async {
    if (await _networkFails()) return const Err(_errNetwork);
    final index = _entries.indexWhere((e) => e.id == id);
    if (index == -1) return const Err(_errNotFound); // «404» mock-а
    return Ok(_entries[index]);
  }

  @override
  Future<Result<WatchEntry>> create(WatchEntry entry) async {
    if (await _networkFails()) return const Err(_errNetwork);
    final created = entry.copyWith(id: _nextId++); // id даёт ХРАНИЛИЩЕ
    _entries.add(created);
    return Ok(created);
  }

  @override
  Future<Result<WatchEntry>> update(WatchEntry entry) async {
    if (await _networkFails()) return const Err(_errNetwork);
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index == -1) return const Err(_errNotFound);
    _entries[index] = entry;
    return Ok(entry);
  }

  @override
  Future<Result<void>> delete(int id) async {
    if (await _networkFails()) return const Err(_errNetwork);
    final index = _entries.indexWhere((e) => e.id == id);
    if (index == -1) return const Err(_errNotFound);
    _entries.removeAt(index);
    return const Ok(null); // «удалил, отдать нечего» — 204
  }
}
