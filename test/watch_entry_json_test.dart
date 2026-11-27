import 'package:flutter_test/flutter_test.dart';
import 'package:watch_list/data/watch_entry.dart';

// Граница JSON: то, что уходит на сервер, возвращается той же записью
void main() {
  final json = <String, dynamic>{
    'id': 7,
    'name': 'Атака титанов',
    'type': 'anime',
    'year': 2013,
    'genres': 'экшен',
    'description': '',
    'episodes': 87,
    'status': 'onHold',
    'myRating': null,
    'watchedEpisodes': 30,
    'note': '',
    'isFavorite': true,
    'createdAt': '2026-11-27T00:00:00.000Z', // лишнее поле не мешает
  };

  test('fromJson разворачивает плоскую запись в WatchEntry + MediaTitle', () {
    final e = WatchEntry.fromJson(json);
    expect(e.id, 7);
    expect(e.media.type, TitleType.anime);
    expect(e.status, WatchStatus.onHold);
    expect(e.myRating, isNull);
    expect(e.isFavorite, isTrue);
  });

  test('toJson — без id, enum-ы по имени; круг замыкается', () {
    final out = WatchEntry.fromJson(json).toJson();
    expect(out.containsKey('id'), isFalse);
    expect(out['status'], 'onHold');
    expect(WatchEntry.fromJson({...out, 'id': 7}).toJson(), out);
  });

  test('тело вне контракта: TypeError и FormatException, не crash-и', () {
    expect(
      () => WatchEntry.fromJson({...json, 'year': '2013'}),
      throwsA(isA<TypeError>()),
    );
    expect(
      () => WatchEntry.fromJson({...json, 'type': 'cartoon'}),
      throwsFormatException,
    );
  });
}
