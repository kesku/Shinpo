import 'package:flutter/material.dart';

/// Consistent "Audio" chip used across list, search, and detail.
class AudioChip extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  const AudioChip({super.key, this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4)});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.volume_up_outlined, size: 14, color: cs.onSecondaryContainer),
          const SizedBox(width: 4),
          Text(
            'Audio',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSecondaryContainer,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

