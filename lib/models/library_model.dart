import 'package:flutter/foundation.dart';

import '../data/result.dart';
import '../data/watch_entry.dart';
import '../data/watch_entry_repository.dart';

// Разделяемое состояние библиотеки: его читают главная, библиотека, списки,
// детали и профиль. Чистый Dart — ни одного widget-а, тестируется без UI
class LibraryModel extends ChangeNotifier {
  LibraryModel(this._repository); // простой DI: хранилище — в конструктор

  final WatchEntryRepository _repository; // тип — ИНТЕРФЕЙС, а не mock

  bool _loading = false;
  String? _error;
  List<WatchEntry> _entries = const [];

  // L5: поиск и ломти — поверх состояния L4
  static const _limit = 20;
  String _search = '';
  int _page = 1;
  bool _hasMore = false;
  bool _loadingMore = false;
  String? _moreError; // ошибка догрузки: уже загруженное остаётся на экране

  bool get isLoading => _loading;
  String? get error => _error;
  String get search => _search;
  bool get hasMore => _hasMore; // полная страница → видимо, есть ещё
  String? get loadMoreError => _moreError;
  // наружу — только для чтения: мутация идёт через методы, которые извещают
  List<WatchEntry> get entries => List.unmodifiable(_entries);

  WatchEntry? byId(int id) => _entries.where((e) => e.id == id).firstOrNull;

  // --- производные данные: статистика считается, а не зашивается в экран ---

  List<WatchEntry> withStatus(WatchStatus status) =>
      _entries.where((e) => e.status == status).toList();

  int countWithStatus(WatchStatus status) =>
      _entries.where((e) => e.status == status).length;

  int get favoritesCount => _entries.where((e) => e.isFavorite).length;

  double? get averageRating {
    final ratings = _entries.map((e) => e.myRating).nonNulls;
    if (ratings.isEmpty) return null;
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }

  // --- загрузка: триада «грузится / данные / ошибка» как состояние ---

  // search: null — прежний фильтр (retry его сохраняет), '' — сбросить
  Future<void> load({String? search}) async {
    _search = search ?? _search;
    _page = 1;
    _moreError = null;
    _loading = true;
    _error = null;
    notifyListeners(); // подписанные экраны входят в состояние «грузится»

    switch (await _repository.fetchAll(limit: _limit, search: _search)) {
      case Ok(:final value):
        _entries = value;
        _hasMore = value.length == _limit;
      case Err(:final msg):
        _error = msg;
    }
    _loading = false;
    notifyListeners(); // …и выходят: с данными или с ошибкой — никогда молча
  }

  // Следующий ломоть приклеивается к списку. Зовётся из itemBuilder, в разгар
  // build: синхронный notifyListeners() здесь бросил бы «markNeedsBuild()
  // called during build» — поэтому _loadingMore ставится БЕЗ извещения
  Future<void> loadMore() async {
    if (_loadingMore || _loading || !_hasMore || _moreError != null) return;
    _loadingMore = true; // guard: без него — дублированные страницы

    final result = await _repository.fetchAll(
      page: _page + 1,
      limit: _limit,
      search: _search,
    );
    switch (result) {
      case Ok(:final value):
        _page += 1;
        // смещение OFFSET плывёт, если запись добавили: id не дублируются
        final known = {for (final e in _entries) e.id};
        _entries = [..._entries, ...value.where((e) => !known.contains(e.id))];
        _hasMore = value.length == _limit;
      case Err(:final msg):
        _moreError = msg; // без этого хвост звал бы упавший сервер без конца
    }
    _loadingMore = false;
    notifyListeners();
  }

  // «Повторить» в хвосте списка: снять ошибку и попросить ломоть снова
  Future<void> retryMore() {
    _moreError = null;
    notifyListeners();
    return loadMore();
  }

  // --- мутации: null — успех, строка — сообщение об ошибке (как validator) ---

  Future<String?> add(WatchEntry draft) async {
    switch (await _repository.create(draft)) {
      case Ok(:final value):
        _entries = [..._entries, value]; // с id-ом, полученным от хранилища
        notifyListeners();
        return null;
      case Err(:final msg):
        return msg; // состояние нетронуто — экран решает, что показать
    }
  }

  Future<String?> update(WatchEntry entry) async {
    switch (await _repository.update(entry)) {
      case Ok(:final value):
        _entries = [
          for (final e in _entries) e.id == value.id ? value : e,
        ];
        notifyListeners();
        return null;
      case Err(:final msg):
        return msg;
    }
  }

  Future<String?> remove(int id) async {
    switch (await _repository.delete(id)) {
      case Ok():
        _entries = _entries.where((e) => e.id != id).toList();
        notifyListeners();
        return null;
      case Err(:final msg):
        return msg;
    }
  }

  Future<String?> toggleFavorite(WatchEntry entry) =>
      update(entry.copyWith(isFavorite: !entry.isFavorite));

  // логика темы: «просмотрено» — значит все эпизоды, «в планах» — ни одного
  Future<String?> setStatus(WatchEntry entry, WatchStatus status) {
    final watched = switch (status) {
      WatchStatus.completed => entry.media.episodes,
      WatchStatus.planned => 0,
      _ => entry.watchedEpisodes,
    };
    return update(entry.copyWith(status: status, watchedEpisodes: watched));
  }
}
