import 'dart:convert';

import 'package:http/http.dart' as http;

// Конверт ошибки, переведённый один раз: {"error":{"code","message"}}.
// code стабилен и принадлежит программе; английский message на экран
// не попадает — русский текст решается здесь, в одном месте
String apiMessage(http.Response res) {
  try {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final code = (body['error'] as Map<String, dynamic>)['code'] as String;
    return switch (code) {
      'VALIDATION_ERROR' => 'Отправленные данные недействительны',
      'UNAUTHORIZED' => 'Неверный email или пароль',
      'EMAIL_TAKEN' => 'Аккаунт с этим email уже существует',
      'NOT_FOUND' => 'Запись не существует',
      _ => 'Ошибка сервера ($code)',
    };
  } on FormatException {
    // тело вне контракта: 500 с HTML, чужой сервер на порту
    return 'Ошибка сервера (${res.statusCode})';
  } on TypeError {
    return 'Ошибка сервера (${res.statusCode})';
  }
}
