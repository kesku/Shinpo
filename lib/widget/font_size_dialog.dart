import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinpo/providers/font_size_provider.dart';

class FontSizeDialog extends ConsumerWidget {
  const FontSizeDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFontSize = ref.watch(fontSizeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Text Size'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Choose your preferred text size for better reading experience.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          ...FontSizeLevel.values.map((fontSize) {
            return RadioListTile<FontSizeLevel>(
              value: fontSize,
              groupValue: currentFontSize,
              onChanged: (value) {
                if (value != null) {
                  ref.read(fontSizeProvider.notifier).setFontSize(value);
                }
              },
              title: Text(
                fontSize.displayName,
                style: TextStyle(
                  fontSize: 16 * fontSize.scale,
                ),
              ),
              subtitle: Text(
                'Sample text at ${fontSize.displayName.toLowerCase()} size',
                style: TextStyle(
                  fontSize: 14 * fontSize.scale,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            );
          }).toList(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
