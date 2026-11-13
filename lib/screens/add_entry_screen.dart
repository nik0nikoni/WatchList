import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../data/mock_data.dart';

class AddEntryScreen extends StatefulWidget {
  final int? id; // null — новая запись, иначе — редактирование записи с этим id

  const AddEntryScreen({super.key, this.id});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _episodesCtrl = TextEditingController();
  final _watchedCtrl = TextEditingController();
  final _genresCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  TitleType _type = TitleType.anime;
  WatchStatus _status = WatchStatus.planned;
  int? _rating;
  bool _favorite = false;

  bool get _isEdit => widget.id != null;

  @override
  void initState() {
    super.initState();
    // в режиме редактирования форма заполняется данными записи из mock-а
    final entry = mockEntries.where((e) => e.id == widget.id).firstOrNull;
    if (entry != null) {
      final media = entry.media;
      _titleCtrl.text = media.name;
      _yearCtrl.text = '${media.year}';
      _episodesCtrl.text = '${media.episodes}';
      _watchedCtrl.text = '${entry.watchedEpisodes}';
      _genresCtrl.text = media.genres;
      _noteCtrl.text = entry.note;
      _type = media.type;
      _status = entry.status;
      _rating = entry.myRating;
    }
  }

  @override
  void dispose() {
    // кто создаёт контроллер, тот его и освобождает
    _titleCtrl.dispose();
    _yearCtrl.dispose();
    _episodesCtrl.dispose();
    _watchedCtrl.dispose();
    _genresCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return; // ошибки уже на экране
    final title = _titleCtrl.text.trim();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_isEdit ? 'Изменения сохранены: $title' : 'Добавлено: $title'),
    ));
    context.pop(); // открыто push-ем → закрывается pop-ом
  }

  // --- валидаторы: null = поле валидно ---

  String? _validateTitle(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Название обязательно';
    if (text.length > 100) return 'Не длиннее 100 символов';
    return null;
  }

  String? _validateYear(String? value) {
    final year = int.tryParse(value ?? '');
    if (year == null) return 'Введите год';
    final maxYear = DateTime.now().year + 5;
    if (year < 1888 || year > maxYear) return 'Год от 1888 до $maxYear';
    return null;
  }

  String? _validateEpisodes(String? value) {
    final episodes = int.tryParse(value ?? '');
    if (episodes == null) return 'Введите число';
    if (episodes < 1) return 'Минимум 1 эпизод';
    if (_type == TitleType.movie && episodes != 1) return 'У фильма 1 эпизод';
    return null;
  }

  String? _validateWatched(String? value) {
    final watched = int.tryParse(value ?? '') ?? 0; // пусто = 0
    final episodes = int.tryParse(_episodesCtrl.text);
    if (episodes == null) return null; // ошибку уже показывает поле «Эпизодов»
    if (watched > episodes) return 'Больше, чем эпизодов ($episodes)';
    if (_status == WatchStatus.completed && watched != episodes) {
      return 'Просмотрено — значит все $episodes';
    }
    if (_status == WatchStatus.planned && watched > 0) {
      return 'В планах — ещё не начато';
    }
    return null;
  }

  String? _validateGenres(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null; // необязательное поле
    if (text.split(',').any((g) => g.trim().isEmpty)) {
      return 'Перечислите через запятую: экшен, драма';
    }
    return null;
  }

  String? _validateRating(int? rating) {
    if (rating != null && _status == WatchStatus.planned) {
      return 'Нельзя оценить то, что ещё не смотрели';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Редактирование' : 'Новая запись'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Название',
                hintText: 'Например, Cowboy Bebop',
                prefixIcon: Icon(Icons.movie_outlined),
                border: OutlineInputBorder(),
              ),
              validator: _validateTitle,
            ),
            const SizedBox(height: 20),
            Text('Тип', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<TitleType>(
              segments: TitleType.values
                  .map((t) => ButtonSegment(value: t, label: Text(t.label)))
                  .toList(),
              selected: {_type},
              onSelectionChanged: (selection) =>
                  setState(() => _type = selection.first),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<WatchStatus>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Статус',
                border: OutlineInputBorder(),
              ),
              items: WatchStatus.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (value) => setState(() => _status = value!),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _yearCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Год выхода',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateYear,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _episodesCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(5),
                    ],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Эпизодов',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateEpisodes,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _watchedCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(5),
              ],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Просмотрено эпизодов',
                hintText: '0',
                border: OutlineInputBorder(),
              ),
              validator: _validateWatched,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _genresCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Жанры',
                hintText: 'экшен, драма',
                border: OutlineInputBorder(),
              ),
              validator: _validateGenres,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              initialValue: _rating,
              decoration: const InputDecoration(
                labelText: 'Моя оценка',
                prefixIcon: Icon(Icons.star_rounded),
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Без оценки')),
                for (var i = 10; i >= 1; i--)
                  DropdownMenuItem(value: i, child: Text('$i')),
              ],
              onChanged: (value) => setState(() => _rating = value),
              validator: _validateRating,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteCtrl,
              maxLines: 4,
              maxLength: 300,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Заметка',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Добавить в избранное'),
              value: _favorite,
              onChanged: (value) => setState(() => _favorite = value),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _save,
              child: const Text('Сохранить'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('Отмена'),
            ),
          ],
        ),
      ),
    );
  }
}
