import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Builds a printable / shareable PDF from an AI report's markdown text.
///
/// We only need to handle the subset of Markdown emitted by Gemini:
///   * `## ` and `### ` headings
///   * Paragraphs
///   * Bullet lists `- item`
///   * Horizontal rules `---`
///   * Inline `**bold**`
class AiReportPdfBuilder {
  AiReportPdfBuilder._();

  static Future<Uint8List> build({
    required String reportText,
    required String periodLabelAr,
    required DateTime createdAt,
    int? assessmentsCount,
  }) async {
    // Load Noto Naskh Arabic from Google Fonts (RTL aware, looks great in PDF).
    final regular = await PdfGoogleFonts.notoNaskhArabicRegular();
    final bold = await PdfGoogleFonts.notoNaskhArabicBold();
    final fallback = await PdfGoogleFonts.notoSansRegular();

    final theme = pw.ThemeData.withFont(
      base: regular,
      bold: bold,
      fontFallback: [fallback],
    );

    final doc = pw.Document(
      title: 'تقرير ذكي - $periodLabelAr',
      author: 'UBSER',
      creator: 'UBSER',
      subject: 'AI assessment report',
      theme: theme,
    );

    final blocks = _parseMarkdown(reportText);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.copyWith(
          marginLeft: 32,
          marginRight: 32,
          marginTop: 36,
          marginBottom: 36,
        ),
        textDirection: pw.TextDirection.rtl,
        header: (ctx) => _header(periodLabelAr, createdAt, assessmentsCount),
        footer: (ctx) => _footer(ctx),
        build: (ctx) => blocks.map(_renderBlock).toList(),
      ),
    );

    return doc.save();
  }

  // ── Header / footer ──────────────────────────────────────────────────────

  static pw.Widget _header(
    String periodLabelAr,
    DateTime createdAt,
    int? assessmentsCount,
  ) {
    final dateFmt = DateFormat('d MMM yyyy', 'ar').format(createdAt);
    final timeFmt = DateFormat('HH:mm').format(createdAt);
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      margin: const pw.EdgeInsets.only(bottom: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColor.fromInt(0xFF0D9488), width: 1.4),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'UBSER - أبصر',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: const PdfColor.fromInt(0xFF0F766E),
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'تقرير الذكاء الاصطناعي',
                  style: const pw.TextStyle(
                    fontSize: 11,
                    color: PdfColor.fromInt(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'الفترة: $periodLabelAr',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor.fromInt(0xFF0F766E),
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'تاريخ الإنشاء: $dateFmt — $timeFmt',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColor.fromInt(0xFF64748B),
                ),
              ),
              if (assessmentsCount != null) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  'عدد التقييمات المعتمدة: $assessmentsCount',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColor.fromInt(0xFF64748B),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _footer(pw.Context ctx) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      margin: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColor.fromInt(0xFFE2E8F0)),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'صفحة ${ctx.pageNumber} من ${ctx.pagesCount}',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromInt(0xFF94A3B8),
            ),
          ),
          pw.Text(
            'UBSER © هذا التقرير تعليمي ولا يغني عن استشارة مختص.',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromInt(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // ── Markdown parsing ─────────────────────────────────────────────────────

  static List<_Block> _parseMarkdown(String src) {
    final lines = src.replaceAll('\r\n', '\n').split('\n');
    final result = <_Block>[];
    final paragraph = <String>[];

    void flushParagraph() {
      if (paragraph.isEmpty) return;
      final text = paragraph.join(' ').trim();
      if (text.isNotEmpty) {
        result.add(_Block.paragraph(text));
      }
      paragraph.clear();
    }

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) {
        flushParagraph();
        continue;
      }
      if (line == '---') {
        flushParagraph();
        result.add(const _Block.divider());
        continue;
      }
      if (line.startsWith('#### ')) {
        flushParagraph();
        result.add(_Block.heading(line.substring(5), level: 4));
        continue;
      }
      if (line.startsWith('### ')) {
        flushParagraph();
        result.add(_Block.heading(line.substring(4), level: 3));
        continue;
      }
      if (line.startsWith('## ')) {
        flushParagraph();
        result.add(_Block.heading(line.substring(3), level: 2));
        continue;
      }
      if (line.startsWith('# ')) {
        flushParagraph();
        result.add(_Block.heading(line.substring(2), level: 1));
        continue;
      }
      if (line.startsWith('- ') || line.startsWith('* ')) {
        flushParagraph();
        result.add(_Block.listItem(line.substring(2)));
        continue;
      }
      paragraph.add(line);
    }
    flushParagraph();
    return result;
  }

  static pw.Widget _renderBlock(_Block b) {
    switch (b.type) {
      case _BlockType.heading:
        return _renderHeading(b.text!, b.level ?? 2);
      case _BlockType.paragraph:
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.RichText(
            text: pw.TextSpan(
              children: _inlineSpans(
                b.text!,
                base: const pw.TextStyle(
                  fontSize: 12,
                  lineSpacing: 4,
                  color: PdfColor.fromInt(0xFF1F2937),
                ),
              ),
            ),
            textDirection: pw.TextDirection.rtl,
          ),
        );
      case _BlockType.listItem:
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4, right: 12),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 4,
                height: 4,
                margin: const pw.EdgeInsets.only(top: 6, left: 8),
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF0D9488),
                  shape: pw.BoxShape.circle,
                ),
              ),
              pw.Expanded(
                child: pw.RichText(
                  text: pw.TextSpan(
                    children: _inlineSpans(
                      b.text!,
                      base: const pw.TextStyle(
                        fontSize: 12,
                        lineSpacing: 3,
                        color: PdfColor.fromInt(0xFF1F2937),
                      ),
                    ),
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
              ),
            ],
          ),
        );
      case _BlockType.divider:
        return pw.Container(
          margin: const pw.EdgeInsets.symmetric(vertical: 12),
          height: 1,
          color: const PdfColor.fromInt(0xFFE2E8F0),
        );
    }
  }

  static pw.Widget _renderHeading(String text, int level) {
    final isH2 = level == 2;
    final color = isH2
        ? const PdfColor.fromInt(0xFF0D9488)
        : const PdfColor.fromInt(0xFF0F172A);
    final fontSize = switch (level) {
      1 => 20.0,
      2 => 16.0,
      3 => 13.5,
      _ => 12.5,
    };
    return pw.Padding(
      padding: pw.EdgeInsets.only(top: isH2 ? 14 : 8, bottom: 6),
      child: pw.RichText(
        text: pw.TextSpan(
          children: _inlineSpans(
            text,
            base: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ),
        textDirection: pw.TextDirection.rtl,
      ),
    );
  }

  /// Renders inline `**bold**` runs by splitting on the pattern.
  static List<pw.InlineSpan> _inlineSpans(
    String text, {
    required pw.TextStyle base,
  }) {
    final pattern = RegExp(r'\*\*(.+?)\*\*');
    final spans = <pw.InlineSpan>[];
    int cursor = 0;
    for (final m in pattern.allMatches(text)) {
      if (m.start > cursor) {
        spans.add(pw.TextSpan(
          text: text.substring(cursor, m.start),
          style: base,
        ));
      }
      spans.add(pw.TextSpan(
        text: m.group(1) ?? '',
        style: base.copyWith(fontWeight: pw.FontWeight.bold),
      ));
      cursor = m.end;
    }
    if (cursor < text.length) {
      spans.add(pw.TextSpan(text: text.substring(cursor), style: base));
    }
    return spans;
  }
}

enum _BlockType { heading, paragraph, listItem, divider }

class _Block {
  const _Block._(this.type, {this.text, this.level});

  const _Block.heading(String text, {required int level})
      : this._(_BlockType.heading, text: text, level: level);
  const _Block.paragraph(String text)
      : this._(_BlockType.paragraph, text: text);
  const _Block.listItem(String text)
      : this._(_BlockType.listItem, text: text);
  const _Block.divider() : this._(_BlockType.divider);

  final _BlockType type;
  final String? text;
  final int? level;
}
