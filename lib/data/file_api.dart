import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_message.dart';
import 'result.dart';
import 'token_store.dart';

// multipart-upload на POST /files: ответ — ОТНОСИТЕЛЬНЫЙ путь, напр. «/files/7»
class FileApi {
  FileApi(this.baseUrl, this.tokens, {this.onUnauthorized});

  final String baseUrl;
  final TokenStore tokens;
  final void Function()? onUnauthorized;

  Future<Result<String>> upload(String path) async {
    try {
      final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/files'))
        ..headers['Authorization'] = 'Bearer ${await tokens.read() ?? ''}'
        ..files.add(await http.MultipartFile.fromPath('file', path));
      // timeout НА send(): иначе сервер, замёрзший ВО ВРЕМЯ передачи, не истечёт
      final res = await http.Response.fromStream(
        await req.send().timeout(const Duration(seconds: 20)),
      );
      if (res.statusCode == 401) {
        await tokens.clear(); // мёртвый пропуск — как в repository
        onUnauthorized?.call();
        return const Err('Сессия истекла — войдите снова');
      }
      if (res.statusCode != 201) return Err(apiMessage(res)); // 400: > 5 МБ
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return Ok(data['url'] as String);
    } on SocketException {
      return const Err('Нет сети — повторите попытку');
    } on TimeoutException {
      return const Err('Сервер не отвечает');
    } on FormatException {
      return const Err('Ответ не тот, что обещан');
    } on TypeError {
      return const Err('Ответ не тот, что обещан');
    }
  }
}
