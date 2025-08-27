import 'package:html/parser.dart' as html;
import 'package:html/dom.dart' as dom;

class HtmlUtils {
  /// Strips HTML tags and decodes entities.
  static String stripHtml(String htmlSource) {
    if (htmlSource.trim().isEmpty) return '';
    final fragment = html.parseFragment(htmlSource);
    return _textFromNode(fragment).replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Extracts plain text from a DOM node (recursively), ignoring styling tags
  /// and <rp>.
  static String _textFromNode(dom.Node node) {
    if (node.nodeType == dom.Node.TEXT_NODE) {
      return (node as dom.Text).data;
    }
    if (node is dom.Element) {
      if (node.localName == 'rp') return '';
      if (node.localName == 'br') return '\n';
    }
    return node.nodes.map(_textFromNode).join('');
  }

  /// Parses NHK Easy article HTML into blocks that the UI can render:
  /// - String for plain paragraphs/list items
  /// - List<Map<String, dynamic>> for mixed content including dictionary words
  static List<dynamic> parseArticleBlocks(String htmlBody) {
    final result = <dynamic>[];
    final fragment = html.parseFragment(htmlBody);

    Iterable<dom.Element> topLevel = fragment.children;
    if (topLevel.isEmpty) {
      // If content has no top-level elements, treat entire fragment as one block.
      final text = stripHtml(htmlBody);
      if (text.isNotEmpty) result.add(text);
      return result;
    }

    for (final el in topLevel) {
      if (el.localName == 'p') {
        final block = _parseInlineBlock(el);
        if (block != null) result.add(block);
      } else if (el.localName == 'ul' || el.localName == 'ol') {
        int index = 1;
        for (final li in el.children.where((c) => c.localName == 'li')) {
          final liBlock = _parseInlineBlock(li);
          if (liBlock is String && liBlock.isNotEmpty) {
            final prefix = el.localName == 'ol' ? '${index++}. ' : '• ';
            result.add('$prefix$liBlock');
          } else if (liBlock != null) {
            result.add(liBlock);
          }
        }
      } else {
        final text = stripHtml(el.outerHtml);
        if (text.isNotEmpty) result.add(text);
      }
    }

    return result;
  }

  /// Parses an inline block (p, li) and splits dictionary spans.
  /// Returns String when simple text, or List<Map> when includes dictionary.
  static dynamic _parseInlineBlock(dom.Element el) {
    final parts = <Map<String, dynamic>>[];
    void flushTextBuffer(StringBuffer buf) {
      if (buf.isNotEmpty) {
        final t = buf.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
        if (t.isNotEmpty) parts.add({'type': 'text', 'text': t});
        buf.clear();
      }
    }

    final buffer = StringBuffer();

    for (final node in el.nodes) {
      if (node is dom.Element && node.localName == 'span' &&
          node.classes.contains('dicWin')) {
        // Flush pending text
        flushTextBuffer(buffer);
        final id = node.attributes['id'] ?? '';
        final text = _textFromNode(node).replaceAll(RegExp(r'\s+'), ' ').trim();
        if (id.isNotEmpty && text.isNotEmpty) {
          parts.add({'type': 'dictionary', 'id': id, 'text': text});
        } else if (text.isNotEmpty) {
          parts.add({'type': 'text', 'text': text});
        }
      } else {
        buffer.write(_textFromNode(node));
      }
    }

    flushTextBuffer(buffer);

    if (parts.isEmpty) {
      final text = stripHtml(el.outerHtml);
      return text.isEmpty ? null : text;
    }
    return parts;
  }
}

