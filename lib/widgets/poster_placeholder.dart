import 'package:flutter/material.dart';

import '../data/mock_data.dart';

class PosterPlaceholder extends StatelessWidget {
  final TitleType type;
  final String name; // от названия зависит цвет: у каждого тайтла свой постер
  final double width;
  final double height;

  const PosterPlaceholder({
    super.key,
    required this.type,
    required this.name,
    this.width = 72,
    this.height = 104,
  });

  IconData get _icon => switch (type) {
    TitleType.movie => Icons.movie_outlined,
    TitleType.series => Icons.tv_outlined,
    TitleType.anime => Icons.auto_awesome_outlined,
  };

  @override
  Widget build(BuildContext context) {
    // стабильный оттенок из названия: одна и та же запись — всегда один цвет
    final hue = name.codeUnits.fold(0, (sum, c) => sum + c * 31) % 360;
    final top = HSLColor.fromAHSL(1, hue.toDouble(), 0.55, 0.42).toColor();
    final bottom = HSLColor.fromAHSL(
      1,
      (hue + 40) % 360.0,
      0.6,
      0.22,
    ).toColor();
    final letter = name.isEmpty ? '?' : name.characters.first.toUpperCase();

    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [top, bottom],
        ),
      ),
      child: Stack(
        children: [
          // крупная полупрозрачная буква названия — как обложка
          Positioned(
            right: -width * 0.08,
            bottom: -height * 0.12,
            child: Text(
              letter,
              style: TextStyle(
                fontSize: height * 0.8,
                fontWeight: FontWeight.w900,
                color: Colors.white.withValues(alpha: 0.14),
                height: 1,
              ),
            ),
          ),
          Positioned(
            left: width * 0.1,
            top: width * 0.1,
            child: Icon(_icon, size: width * 0.26, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
