import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html;
import 'package:html/dom.dart' as dom;

class RubyTextWidget extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final bool showRuby;

  const RubyTextWidget({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.showRuby = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultStyle =
        style ?? theme.textTheme.bodyMedium ?? const TextStyle();

    final spans = _buildSpansFromHtml(text, defaultStyle, theme, showRuby);

    return RichText(
      text: TextSpan(children: spans, style: defaultStyle),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      textAlign: textAlign ?? TextAlign.start,
    );
  }

  List<InlineSpan> _buildSpansFromHtml(
    String htmlSource,
    TextStyle style,
    ThemeData theme,
    bool showRuby,
  ) {
    final fragment = html.parseFragment(htmlSource);
    final List<InlineSpan> spans = [];

    void walk(dom.Node node) {
      if (node.nodeType == dom.Node.TEXT_NODE) {
        final t = (node as dom.Text).data;
        if (t.isNotEmpty) spans.add(TextSpan(text: t));
        return;
      }
      if (node is! dom.Element) {
        return;
      }

      switch (node.localName) {
        case 'ruby':
          final base = _extractRubyBase(node).trim();
          final rubies = _extractRubyTexts(node).join(' ');
          if (base.isEmpty) break;
          if (!showRuby) {
            spans.add(TextSpan(text: base));
            break;
          }
          spans.add(WidgetSpan(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (rubies.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      rubies,
                      style: style.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: (style.fontSize ?? 16) * 0.6,
                        height: 1.0,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                Text(base, style: style),
              ],
            ),
          ));
          break;
        case 'br':
          spans.add(const TextSpan(text: '\n'));
          break;
        default:
          for (final child in node.nodes) {
            walk(child);
          }
      }
    }

    for (final node in fragment.nodes) {
      walk(node);
    }
    return spans;
  }

  String _extractRubyBase(dom.Element rubyEl) {
    final buffer = StringBuffer();
    for (final n in rubyEl.nodes) {
      if (n is dom.Element && (n.localName == 'rt' || n.localName == 'rp')) {
        continue;
      }
      buffer.write(_nodeText(n));
    }
    return buffer.toString();
  }

  List<String> _extractRubyTexts(dom.Element rubyEl) {
    return rubyEl.children
        .where((c) => c.localName == 'rt')
        .map((rt) => _nodeText(rt).trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  String _nodeText(dom.Node node) {
    if (node.nodeType == dom.Node.TEXT_NODE) {
      return (node as dom.Text).data;
    }
    return node.nodes.map(_nodeText).join('');
  }
}
