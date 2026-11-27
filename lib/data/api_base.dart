import 'package:flutter/foundation.dart';

// Сервер на ноутбуке: эмулятор Android не знает «localhost» — для него это
// 10.0.2.2; на десктопе и в браузере — localhost; на телефоне — IP ноутбука.
// Отдельный файл: адрес нужен корню (main) и показу постеров (Image.network)
final apiBase = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
    ? 'http://10.0.2.2:8080'
    : 'http://localhost:8080';
