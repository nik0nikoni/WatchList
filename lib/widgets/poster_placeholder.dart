import 'package:flutter/material.dart';
import '../data/mock_data.dart';

class PosterPlaceholder extends StatelessWidget {
  final TitleType type;
  final double width;
  final double height;

  const PosterPlaceholder({
    super.key,
    required this.type,
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
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primaryContainer, scheme.tertiaryContainer],
        ),
      ),
      child: Icon(
        _icon,
        size: width * 0.45,
        color: scheme.onPrimaryContainer,
      ),
    );
  }
}