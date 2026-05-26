import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';

import '../routes.dart';
import '../util/breakpoints.dart';
import '../widgets/app_shell.dart';

/// Renders the project's privacy policy from the bundled `PRIVACY.md` asset.
///
/// Source of truth: `PRIVACY.md` at the repo root, also published at
/// https://monsiu.github.io/custom-rr/privacy/. Edit that file to update both
/// the in-app and online versions.
class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  Future<List<_Block>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_Block>> _load() async {
    final String raw = await rootBundle.loadString('PRIVACY.md');
    return _MarkdownParser.parse(raw);
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Privacy policy',
      selectedRoute: AppRoutes.about,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: Breakpoints.readingMaxWidth,
          ),
          child: FutureBuilder<List<_Block>>(
            future: _future,
            builder: (BuildContext context, AsyncSnapshot<List<_Block>> snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Could not load privacy policy: ${snap.error}'),
                );
              }
              final List<_Block> blocks = snap.data ?? const <_Block>[];
              return ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                children: <Widget>[
                  for (final _Block b in blocks) _renderBlock(context, b),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('View online version'),
                      onPressed: () => launchUrl(
                        Uri.parse(
                          'https://monsiu.github.io/custom-rr/privacy/',
                        ),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

Widget _renderBlock(BuildContext context, _Block block) {
  final TextTheme text = Theme.of(context).textTheme;
  switch (block) {
    case _Heading(:final int level, :final List<_Inline> inlines):
      final TextStyle? style = switch (level) {
        1 => text.headlineSmall,
        2 => text.titleLarge,
        _ => text.titleMedium,
      };
      return Padding(
        padding: EdgeInsets.only(
          top: level == 1 ? 0 : 28,
          bottom: level == 1 ? 8 : 10,
        ),
        child: _InlineText(inlines: inlines, style: style),
      );
    case _Paragraph(:final List<_Inline> inlines):
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _InlineText(inlines: inlines, style: text.bodyLarge),
      );
    case _BulletList(:final List<List<_Inline>> items):
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (final List<_Inline> item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 9, right: 10, left: 4),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Expanded(
                      child:
                          _InlineText(inlines: item, style: text.bodyLarge),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    case _Table(
        :final List<String> headers,
        :final List<List<List<_Inline>>> rows
      ):
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (final List<List<_Inline>> row in rows) ...<Widget>[
              _TableRowCard(headers: headers, cells: row),
              const SizedBox(height: 8),
            ],
          ],
        ),
      );
  }
}

class _TableRowCard extends StatelessWidget {
  const _TableRowCard({required this.headers, required this.cells});

  final List<String> headers;
  final List<List<_Inline>> cells;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextStyle? labelStyle = text.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
      letterSpacing: 0.5,
    );

    // Use the first column as the card title, rest as labeled sections.
    final List<_Inline> titleCell =
        cells.isNotEmpty ? cells.first : <_Inline>[];

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _InlineText(inlines: titleCell, style: text.titleMedium),
            const SizedBox(height: 10),
            for (int i = 1; i < cells.length && i < headers.length; i++) ...<Widget>[
              Text(headers[i].toUpperCase(), style: labelStyle),
              const SizedBox(height: 2),
              _InlineText(inlines: cells[i], style: text.bodyMedium),
              if (i < cells.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _InlineText extends StatelessWidget {
  const _InlineText({required this.inlines, this.style});

  final List<_Inline> inlines;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextStyle base = style ?? DefaultTextStyle.of(context).style;
    final TextStyle codeStyle = base.copyWith(
      fontFamily: 'monospace',
      fontFamilyFallback: const <String>['RobotoMono', 'Courier'],
      fontSize: (base.fontSize ?? 14) * 0.92,
      backgroundColor: scheme.surfaceContainerHighest,
    );
    final TextStyle linkStyle = base.copyWith(
      color: scheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: scheme.primary,
    );
    final TextStyle boldStyle = base.copyWith(fontWeight: FontWeight.w600);

    final List<TextSpan> spans = <TextSpan>[];
    for (final _Inline span in inlines) {
      switch (span) {
        case _TextRun(:final String text, :final bool bold):
          spans.add(TextSpan(text: text, style: bold ? boldStyle : base));
        case _Code(:final String text):
          spans.add(TextSpan(text: text, style: codeStyle));
        case _Link(:final String label, :final String url):
          final TapGestureRecognizer recognizer = TapGestureRecognizer()
            ..onTap = () => launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                );
          spans.add(
            TextSpan(text: label, style: linkStyle, recognizer: recognizer),
          );
      }
    }
    return Text.rich(TextSpan(style: base, children: spans));
  }
}

// ---------------------------------------------------------------------------
// Block / inline model
// ---------------------------------------------------------------------------

sealed class _Block {
  const _Block();
}

class _Heading extends _Block {
  const _Heading(this.level, this.inlines);
  final int level;
  final List<_Inline> inlines;
}

class _Paragraph extends _Block {
  const _Paragraph(this.inlines);
  final List<_Inline> inlines;
}

class _BulletList extends _Block {
  const _BulletList(this.items);
  final List<List<_Inline>> items;
}

class _Table extends _Block {
  const _Table(this.headers, this.rows);
  final List<String> headers;
  final List<List<List<_Inline>>> rows;
}

sealed class _Inline {
  const _Inline();
}

class _TextRun extends _Inline {
  const _TextRun(this.text, {this.bold = false});
  final String text;
  final bool bold;
}

class _Code extends _Inline {
  const _Code(this.text);
  final String text;
}

class _Link extends _Inline {
  const _Link(this.label, this.url);
  final String label;
  final String url;
}

// ---------------------------------------------------------------------------
// Minimal markdown parser tailored to the subset used in PRIVACY.md.
// Supports: H1/H2/H3, paragraphs, `-` bullets (with 2-space continuation),
// GFM tables, **bold**, `code`, [text](url), <autolinks for url or email>.
// ---------------------------------------------------------------------------

class _MarkdownParser {
  static List<_Block> parse(String source) {
    final List<String> lines = source.replaceAll('\r\n', '\n').split('\n');
    final List<_Block> blocks = <_Block>[];

    int i = 0;
    while (i < lines.length) {
      final String line = lines[i];

      if (line.trim().isEmpty) {
        i++;
        continue;
      }

      // Heading.
      final RegExpMatch? h = RegExp(r'^(#{1,3})\s+(.*)$').firstMatch(line);
      if (h != null) {
        final int level = h.group(1)!.length;
        blocks.add(_Heading(level, _parseInline(h.group(2)!)));
        i++;
        continue;
      }

      // Table: header row + separator row.
      if (line.startsWith('|') &&
          i + 1 < lines.length &&
          RegExp(r'^\|[\s\-:|]+\|\s*$').hasMatch(lines[i + 1])) {
        final List<String> headers = _splitTableRow(line);
        i += 2;
        final List<List<List<_Inline>>> rows = <List<List<_Inline>>>[];
        while (i < lines.length && lines[i].startsWith('|')) {
          final List<String> rawCells = _splitTableRow(lines[i]);
          rows.add(<List<_Inline>>[
            for (final String cell in rawCells) _parseInline(cell),
          ]);
          i++;
        }
        blocks.add(_Table(headers, rows));
        continue;
      }

      // Bullet list.
      if (RegExp(r'^[-*]\s+').hasMatch(line)) {
        final List<List<_Inline>> items = <List<_Inline>>[];
        StringBuffer current =
            StringBuffer(line.replaceFirst(RegExp(r'^[-*]\s+'), ''));
        i++;
        while (i < lines.length) {
          final String l = lines[i];
          if (l.trim().isEmpty) break;
          if (RegExp(r'^[-*]\s+').hasMatch(l)) {
            items.add(_parseInline(current.toString()));
            current = StringBuffer(l.replaceFirst(RegExp(r'^[-*]\s+'), ''));
            i++;
            continue;
          }
          if (l.startsWith('  ')) {
            // Continuation of current bullet.
            current.write(' ');
            current.write(l.trim());
            i++;
            continue;
          }
          break;
        }
        items.add(_parseInline(current.toString()));
        blocks.add(_BulletList(items));
        continue;
      }

      // Paragraph: consume until blank line / heading / table / list.
      final StringBuffer p = StringBuffer(line);
      i++;
      while (i < lines.length) {
        final String l = lines[i];
        if (l.trim().isEmpty) break;
        if (RegExp(r'^#{1,3}\s+').hasMatch(l)) break;
        if (l.startsWith('|')) break;
        if (RegExp(r'^[-*]\s+').hasMatch(l)) break;
        p.write(' ');
        p.write(l.trim());
        i++;
      }
      blocks.add(_Paragraph(_parseInline(p.toString())));
    }

    return blocks;
  }

  static List<String> _splitTableRow(String line) {
    String s = line.trim();
    if (s.startsWith('|')) s = s.substring(1);
    if (s.endsWith('|')) s = s.substring(0, s.length - 1);
    return s.split('|').map((String c) => c.trim()).toList();
  }

  // Inline parser. Scans char-by-char looking for the next special marker.
  // Markers handled: backtick code, **bold**, [text](url), <autolink>.
  static List<_Inline> _parseInline(String text) {
    final List<_Inline> out = <_Inline>[];
    final StringBuffer plain = StringBuffer();

    void flushPlain() {
      if (plain.isEmpty) return;
      out.add(_TextRun(plain.toString()));
      plain.clear();
    }

    int i = 0;
    while (i < text.length) {
      // Inline code.
      if (text[i] == '`') {
        final int end = text.indexOf('`', i + 1);
        if (end != -1) {
          flushPlain();
          out.add(_Code(text.substring(i + 1, end)));
          i = end + 1;
          continue;
        }
      }

      // Bold ** ... **.
      if (i + 1 < text.length && text[i] == '*' && text[i + 1] == '*') {
        final int end = text.indexOf('**', i + 2);
        if (end != -1) {
          flushPlain();
          final List<_Inline> inner =
              _parseInline(text.substring(i + 2, end));
          for (final _Inline span in inner) {
            if (span is _TextRun) {
              out.add(_TextRun(span.text, bold: true));
            } else {
              out.add(span);
            }
          }
          i = end + 2;
          continue;
        }
      }

      // Link [label](url).
      if (text[i] == '[') {
        final int closeBracket = text.indexOf(']', i + 1);
        if (closeBracket != -1 &&
            closeBracket + 1 < text.length &&
            text[closeBracket + 1] == '(') {
          final int closeParen = text.indexOf(')', closeBracket + 2);
          if (closeParen != -1) {
            flushPlain();
            final String label = text.substring(i + 1, closeBracket);
            final String url = text.substring(closeBracket + 2, closeParen);
            out.add(_Link(label, url));
            i = closeParen + 1;
            continue;
          }
        }
      }

      // Autolink <url> or <email>.
      if (text[i] == '<') {
        final int close = text.indexOf('>', i + 1);
        if (close != -1) {
          final String inner = text.substring(i + 1, close);
          if (inner.contains('://')) {
            flushPlain();
            out.add(_Link(inner, inner));
            i = close + 1;
            continue;
          }
          if (RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(inner)) {
            flushPlain();
            out.add(_Link(inner, 'mailto:$inner'));
            i = close + 1;
            continue;
          }
        }
      }

      plain.write(text[i]);
      i++;
    }
    flushPlain();
    return out;
  }
}
