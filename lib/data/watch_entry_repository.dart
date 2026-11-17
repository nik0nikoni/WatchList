import 'result.dart';
import 'watch_entry.dart';

// Контракт: ЧТО можно просить у хранилища, а не КАК. На L5 каждый метод
// становится запросом к backend-у, экраны и модели при этом не меняются:
//   fetchAll()    → GET    /entries
//   fetchById(id) → GET    /entries/{id}   (Err при 404)
//   create(entry) → POST   /entries        (id даёт сервер)
//   update(entry) → PUT    /entries/{id}
//   delete(id)    → DELETE /entries/{id}   (204 → Result<void>)
abstract class WatchEntryRepository {
  Future<Result<List<WatchEntry>>> fetchAll();
  Future<Result<WatchEntry>> fetchById(int id);
  Future<Result<WatchEntry>> create(WatchEntry entry);
  Future<Result<WatchEntry>> update(WatchEntry entry);
  Future<Result<void>> delete(int id);
}
