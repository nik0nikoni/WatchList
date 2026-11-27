// Доменная модель: переживёт mock — на L5 её импортирует и http-вариант
// хранилища, поэтому она живёт отдельно от seed-списка

enum TitleType { movie, series, anime }

enum WatchStatus { planned, watching, completed, onHold, dropped }

extension TitleTypeLabel on TitleType {
  String get label => switch (this) {
    TitleType.movie => 'Фильм',
    TitleType.series => 'Сериал',
    TitleType.anime => 'Аниме',
  };
}

extension WatchStatusLabel on WatchStatus {
  String get label => switch (this) {
    WatchStatus.planned => 'В планах',
    WatchStatus.watching => 'Смотрю',
    WatchStatus.completed => 'Просмотрено',
    WatchStatus.onHold => 'Отложено',
    WatchStatus.dropped => 'Брошено',
  };
}

class MediaTitle {
  final String name;
  final TitleType type;
  final int year;
  final String genres;
  final String description;
  final int episodes;

  const MediaTitle({
    required this.name,
    required this.type,
    required this.year,
    required this.genres,
    required this.description,
    required this.episodes,
  });
}

class WatchEntry {
  final int id; // идентичность, которая путешествует в адресе: /library/3
  final MediaTitle media;
  final WatchStatus status;
  final int? myRating; // 1-10
  final int watchedEpisodes;
  final String note;
  final bool isFavorite;

  const WatchEntry({
    required this.id,
    required this.media,
    required this.status,
    this.myRating,
    this.watchedEpisodes = 0,
    this.note = '',
    this.isFavorite = false,
  });

  // --- граница JSON (L5): сервер хранит запись плоско, MediaTitle — внутри ---

  factory WatchEntry.fromJson(Map<String, dynamic> j) => WatchEntry(
    id: j['id'] as int,
    media: MediaTitle(
      name: j['name'] as String,
      type: _byName(TitleType.values, j['type']),
      year: j['year'] as int,
      genres: j['genres'] as String? ?? '',
      description: j['description'] as String? ?? '',
      episodes: j['episodes'] as int? ?? 1,
    ),
    status: _byName(WatchStatus.values, j['status']),
    myRating: j['myRating'] as int?, // null = оценки нет
    watchedEpisodes: j['watchedEpisodes'] as int? ?? 0,
    note: j['note'] as String? ?? '',
    isFavorite: j['isFavorite'] as bool? ?? false,
  );

  // без id — идентичность даёт сервер (C8); enum-ы уходят по имени
  Map<String, dynamic> toJson() => {
    'name': media.name,
    'type': media.type.name,
    'year': media.year,
    'genres': media.genres,
    'description': media.description,
    'episodes': media.episodes,
    'status': status.name,
    'myRating': myRating,
    'watchedEpisodes': watchedEpisodes,
    'note': note,
    'isFavorite': isFavorite,
  };

  // неизвестное имя enum-а — тело вне контракта: FormatException, как у
  // jsonDecode, а не ArgumentError, который не поймала бы ни одна ветка
  static T _byName<T extends Enum>(List<T> values, Object? name) =>
      values.asNameMap()[name] ??
      (throw FormatException('Неизвестное значение: $name'));

  // «та же запись, другие поля»: id даёт хранилище, статус и избранное
  // меняются с экрана деталей
  WatchEntry copyWith({
    int? id,
    WatchStatus? status,
    int? watchedEpisodes,
    bool? isFavorite,
  }) => WatchEntry(
    id: id ?? this.id,
    media: media,
    status: status ?? this.status,
    myRating: myRating,
    watchedEpisodes: watchedEpisodes ?? this.watchedEpisodes,
    note: note,
    isFavorite: isFavorite ?? this.isFavorite,
  );
}
