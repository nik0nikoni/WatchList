import 'package:flutter/material.dart';
import '../data/mock_data.dart';

class StatusBadge extends StatelessWidget {
  final WatchStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (status) {
      WatchStatus.watching => (scheme.primaryContainer, scheme.onPrimaryContainer),
      WatchStatus.planned => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      WatchStatus.completed => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      WatchStatus.onHold => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
      WatchStatus.dropped => (scheme.errorContainer, scheme.onErrorContainer),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}