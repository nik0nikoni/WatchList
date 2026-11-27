import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_message.dart';
import 'result.dart';
import 'token_store.dart';
import 'watch_entry.dart';
import 'watch_entry_repository.dart';

// Вторая реализация интерфейса L4: каждый метод — запрос к своему backend-у.
// Интерфейс не изменился ни на букву — экраны и модели об этом не узнают
class HttpWatchEntryRepository implements WatchEntryRepository {
  HttpWatchEntryRepository(this.baseUrl, this.tokens, {this.onUnauthorized});

  final String baseUrl;
  final TokenStore tokens;
  final void Function()? onUnauthorized; // решает корень: назад на login

  static const _timeout = Duration(seconds: 8);

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<Map<String, String>> _headers() async => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${await tokens.read() ?? ''}', // C8: Bearer
  };

  // 401 = пропуск умер: token выбрасывается (C9), корень навигирует
  Future<String> _sessionDied() async {
    await tokens.clear();
    onUnauthorized?.call();
    return 'Сессия истекла — войдите снова';
  }

  // Общий скелет каждого метода: запрос с timeout-ом, вердикт по статусу,
  // разбор тела на хорошей ветке — и три слоя отказа, сходящиеся в Err(msg)
  Future<Result<T>> _call<T>(
    Future<http.Response> Function() send,
    int okStatus,
    T Function(http.Response res) parse,
  ) async {
    try {
      final res = await send().timeout(_timeout);
      if (res.statusCode == 401) return Err(await _sessionDied());
      // слой 2: дурная весть сервера не бросает — читается через if
      if (res.statusCode != okStatus) return Err(apiMessage(res));
      return Ok(parse(res));
      // слой 1: упавшая дорога бросает — ловится по конкретным типам
    } on SocketException {
      return const Err('Нет сети — повторите попытку');
    } on TimeoutException {
      return const Err('Сервер не отвечает');
      // слой 3: тело-сюрприз падает при разборе (jsonDecode, cast-ы fromJson)
    } on FormatException {
      return const Err('Ответ не тот, что обещан');
    } on TypeError {
      return const Err('Ответ не тот, что обещан');
    }
  }

  static WatchEntry _entry(http.Response res) =>
      WatchEntry.fromJson(jsonDecode(res.body) as Map<String, dynamic>);

  @override
  Future<Result<List<WatchEntry>>> fetchAll() => _call(
    () async => http.get(_uri('/entries'), headers: await _headers()),
    200,
    (res) {
      final data = jsonDecode(res.body) as Map<String, dynamic>; // конверт!
      return (data['items'] as List)
          .map((e) => WatchEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    },
  );

  @override
  Future<Result<WatchEntry>> fetchById(int id) => _call(
    () async => http.get(_uri('/entries/$id'), headers: await _headers()),
    200, // 404 → apiMessage → «Запись не существует»
    _entry,
  );

  @override
  Future<Result<WatchEntry>> create(WatchEntry entry) => _call(
    () async => http.post(
      _uri('/entries'),
      headers: await _headers(),
      body: jsonEncode(entry.toJson()),
    ),
    201, // ответ — запись с id, выданным сервером
    _entry,
  );

  @override
  Future<Result<WatchEntry>> update(WatchEntry entry) => _call(
    () async => http.put(
      _uri('/entries/${entry.id}'),
      headers: await _headers(),
      body: jsonEncode(entry.toJson()),
    ),
    200,
    _entry,
  );

  @override
  Future<Result<void>> delete(int id) => _call(
    () async => http.delete(_uri('/entries/$id'), headers: await _headers()),
    204,
    (_) {}, // тело пустое — без jsonDecode на нём (ловушка C8)
  );
}
