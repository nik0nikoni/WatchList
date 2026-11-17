import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/watch_entry.dart';
import '../models/library_model.dart';
import '../widgets/error_view.dart';

class AddEntryScreen extends StatelessWidget {
  final int? id; // null — новая запись, иначе — редактирование записи с этим id

  const AddEntryScreen({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    final id = this.id;
    if (id == null) return const _EntryForm(initial: null);

    // редактирование: запись берётся из модели — те же три состояния
    final model = context.watch<LibraryModel>();
    final entry = model.byId(id);
    if (entry != null) return _EntryForm(key: ValueKey(id), initial: entry);

    final Widget body;
    if (model.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (model.error != null) {
      body = ErrorView(
        message: model.error!,
        onRetry: () => context.read<LibraryModel>().load(),
      );
    } else {
      body = Center(child: Text('Запись #$id не существует'));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Редактирование')),
      body: body,
    );
  }
}

class _EntryForm extends StatefulWidget {
  final WatchEntry? initial; // null — новая запись

  const _EntryForm({super.key, required this.initial});

  @override
  State<_EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<_EntryForm> {
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
  bool _saving = false; // пока «запрос» летит, повторный submit заблокирован

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    // в режиме редактирования форма заполняется данными записи из модели
    final entry = widget.initial;
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
      _favorite = entry.isFavorite;
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

  // валидный submit ПИШЕТ через модель (а та — через repository), затем уходит
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return; // валидация L3, нетронута

    final initial = widget.initial;
    final title = _titleCtrl.text.trim();
    final entry = WatchEntry(
      // 0 — временный id: настоящую идентичность даст хранилище (на L5: сервер)
      id: initial?.id ?? 0,
      media: MediaTitle(
        name: title,
        type: _type,
        year: int.parse(_yearCtrl.text),
        genres: _genresCtrl.text.trim(),
        description: initial?.media.description ?? '',
        episodes: int.parse(_episodesCtrl.text),
      ),
      status: _status,
      myRating: _rating,
      watchedEpisodes: int.tryParse(_watchedCtrl.text) ?? 0,
      note: _noteCtrl.text.trim(),
      isFavorite: _favorite,
    );

    setState(() => _saving = true);
    final model = context.read<LibraryModel>(); // read: это действие, не build
    final error = _isEdit ? await model.update(entry) : await model.add(entry);
    if (!mounted) return; // экран может умереть, пока «запрос» летит
    setState(() => _saving = false);

    final messenger = ScaffoldMessenger.of(context);
    if (error != null) {
      // данные остаются в полях — можно повторить
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          _isEdit ? 'Изменения сохранены: $title' : 'Добавлено: $title',
        ),
      ),
    );
    context.pop(); // список позади УЖЕ обновлён — notifyListeners известил его
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
      appBar: AppBar(title: Text(_isEdit ? 'Редактирование' : 'Новая запись')),
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
              decoration: const InputDecoration(labelText: 'Статус'),
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
                    decoration: const InputDecoration(labelText: 'Год выхода'),
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
                    decoration: const InputDecoration(labelText: 'Эпизодов'),
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
              ),
              validator: _validateGenres,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              initialValue: _rating,
              decoration: const InputDecoration(
                labelText: 'Моя оценка',
                prefixIcon: Icon(Icons.star_rounded),
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
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('Сохранить'),
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
