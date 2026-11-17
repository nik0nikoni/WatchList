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
