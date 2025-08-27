import 'package:flutter/material.dart';

class RubyTextWidget extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  const RubyTextWidget({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultStyle =
        style ?? theme.textTheme.bodyMedium ?? const TextStyle();

    final List<InlineSpan> spans = [];

    final rubyPattern = RegExp(r'<ruby>(.*?)<rt>(.*?)</rt></ruby>');
    final matches = rubyPattern.allMatches(text);

    if (matches.isEmpty) {
      return Text(
        text,
        style: defaultStyle,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      );
    }

    int lastIndex = 0;

    for (final match in matches) {
      if (match.start > lastIndex) {
        final beforeText = text.substring(lastIndex, match.start);
        if (beforeText.trim().isNotEmpty) {
          spans.add(TextSpan(
            text: beforeText,
            style: defaultStyle,
          ));
        }
      }

      final baseText = match.group(1) ?? '';

      final rubyText = match.group(2) ?? '';
      spans.add(WidgetSpan(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              rubyText,
              style: defaultStyle.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: (defaultStyle.fontSize ?? 16) * 0.6,
                fontWeight: FontWeight.normal,
              ),
            ),
            Text(
              baseText,
              style: defaultStyle,
            ),
          ],
        ),
      ));

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      final afterText = text.substring(lastIndex);
      if (afterText.trim().isNotEmpty) {
        spans.add(TextSpan(
          text: afterText,
          style: defaultStyle,
        ));
      }
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      textAlign: textAlign ?? TextAlign.start,
    );
  }
}
