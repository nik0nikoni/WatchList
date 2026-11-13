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

  const WatchEntry({
    required this.id,
    required this.media,
    required this.status,
    this.myRating,
    this.watchedEpisodes = 0,
    this.note = '',
  });
}

const mockEntries = [
  WatchEntry(
    id: 1,
    media: MediaTitle(
      name: 'Начало',
      type: TitleType.movie,
      year: 2010,
      genres: 'фантастика, триллер',
      description: 'Вор, крадущий секреты через сны, получает задание внедрить идею в сознание наследника корпорации.',
      episodes: 1,
    ),
    status: WatchStatus.completed,
    myRating: 9,
    watchedEpisodes: 1,
    note: 'Пересмотреть в оригинале',
  ),
  WatchEntry(
    id: 2,
    media: MediaTitle(
      name: 'Во все тяжкие',
      type: TitleType.series,
      year: 2008,
      genres: 'драма, криминал',
      description: 'Школьный учитель химии узнаёт о смертельном диагнозе и начинает варить метамфетамин.',
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
      genres: 'экшен, драма, фэнтези',
      description:
          'Остатки человечества прячутся за стенами от гигантских титанов.',
      episodes: 87,
    ),
    status: WatchStatus.watching,
    myRating: 9,
    watchedEpisodes: 59,
  ),
  WatchEntry(
    id: 4,
    media: MediaTitle(
      name: 'Стальной алхимик: Братство',
      type: TitleType.anime,
      year: 2009,
      genres: 'приключения, фэнтези',
      description: 'Двое братьев-алхимиков ищут философский камень, чтобы вернуть утраченные тела.',
      episodes: 64,
    ),
    status: WatchStatus.completed,
    myRating: 10,
    watchedEpisodes: 64,
  ),
  WatchEntry(
    id: 5,
    media: MediaTitle(
      name: 'Интерстеллар',
      type: TitleType.movie,
      year: 2014,
      genres: 'фантастика, драма',
      description: 'Экспедиция отправляется через червоточину на поиски нового дома для человечества.',
      episodes: 1,
    ),
    status: WatchStatus.planned,
  ),
  WatchEntry(
    id: 6,
    media: MediaTitle(
      name: 'Тьма',
      type: TitleType.series,
      year: 2017,
      genres: 'мистика, детектив',
      description: 'Исчезновение ребёнка в немецком городке раскрывает тайны четырёх поколений.',
      episodes: 26,
    ),
    status: WatchStatus.planned,
  ),
  WatchEntry(
    id: 7,
    media: MediaTitle(
      name: 'Унесённые призраками',
      type: TitleType.anime,
      year: 2001,
      genres: 'фэнтези, семейный',
      description: 'Девочка попадает в мир духов и должна спасти родителей, превращённых в свиней.',
      episodes: 1,
    ),
    status: WatchStatus.completed,
    myRating: 9,
    watchedEpisodes: 1,
  ),
  WatchEntry(
    id: 8,
    media: MediaTitle(
      name: 'Одни из нас',
      type: TitleType.series,
      year: 2023,
      genres: 'драма, постапокалипсис',
      description: 'Контрабандист сопровождает девочку через США, опустошённые грибковой пандемией.',
      episodes: 9,
    ),
    status: WatchStatus.watching,
    watchedEpisodes: 4,
  ),
  WatchEntry(
    id: 9,
    media: MediaTitle(
      name: 'Ванпанчмен',
      type: TitleType.anime,
      year: 2015,
      genres: 'экшен, комедия',
      description: 'Герой, побеждающий любого врага одним ударом, скучает от отсутствия достойных противников.',
      episodes: 12,
    ),
    status: WatchStatus.onHold,
    myRating: 8,
    watchedEpisodes: 7,
  ),
  WatchEntry(
    id: 10,
    media: MediaTitle(
      name: 'Токийский гуль',
      type: TitleType.anime,
      year: 2014,
      genres: 'ужасы, экшен',
      description: 'Студент становится наполовину гулем после неудачного свидания и учится жить в двух мирах.',
      episodes: 12,
    ),
    status: WatchStatus.dropped,
    myRating: 5,
    watchedEpisodes: 5,
    note: 'Бросил после 5 серии, не зашло',
  ),
];
