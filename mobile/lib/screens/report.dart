import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../checklist.dart';
import '../store.dart';
import '../theme.dart' show clp;

/// Vista previa del informe, con botón para compartir (WhatsApp, correo, etc.).
class ReportScreen extends StatelessWidget {
  final Inspection inspection;
  const ReportScreen({super.key, required this.inspection});

  @override
  Widget build(BuildContext context) {
    final name = 'Informe ${inspection.vehiculo} ${inspection.patente}'.trim().replaceAll(RegExp(r'\s+'), ' ');
    return Scaffold(
      appBar: AppBar(title: const Text('Informe')),
      body: PdfPreview(
        build: (_) => buildReport(inspection),
        pdfFileName: '$name.pdf',
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        allowPrinting: false,
        loadingWidget: const CircularProgressIndicator(),
      ),
    );
  }
}

const _green = PdfColor.fromInt(0xFF0B2418);
const _gold = PdfColor.fromInt(0xFFD4A62A);
const _gold300 = PdfColor.fromInt(0xFFF3D36B);
const _cream = PdfColor.fromInt(0xFFF7F3E8);
const _muted = PdfColor.fromInt(0xFF5F6862);
const _line = PdfColor.fromInt(0xFFE4DFD1);
const _sev = [PdfColor.fromInt(0xFF1F8A4C), PdfColor.fromInt(0xFFC98A06), PdfColor.fromInt(0xFFC0392B)];
const _sevBg = [PdfColor.fromInt(0xFFE3F4EA), PdfColor.fromInt(0xFFFFF3D6), PdfColor.fromInt(0xFFFDE4E1)];

Future<Uint8List> buildReport(Inspection i) async {
  final logo = pw.MemoryImage((await rootBundle.load('assets/logo-wordmark.jpg')).buffer.asUint8List());
  final shield = pw.MemoryImage((await rootBundle.load('assets/logo-shield.jpg')).buffer.asUint8List());
  final font = await PdfGoogleFonts.interRegular();
  final bold = await PdfGoogleFonts.interBold();
  final fecha = DateFormat("d 'de' MMMM 'de' y", 'es').format(i.fecha);
  final km = int.tryParse(i.km);
  final c = i.counts();
  final score = i.score;
  final hallazgos = i.hallazgos;

  // Fotos con su leyenda (sección y punto).
  final fotos = <(pw.MemoryImage, String)>[];
  for (final s in checklist) {
    for (final it in s.items) {
      for (final f in i.results[it.id]?.fotos ?? const <String>[]) {
        final file = Store.I.photoFile(f);
        if (await file.exists()) fotos.add((pw.MemoryImage(await file.readAsBytes()), '${s.title}: ${it.label}'));
      }
    }
  }

  pw.Widget pill(String text, int sev) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: pw.BoxDecoration(color: sev < 0 ? _cream : _sevBg[sev], borderRadius: pw.BorderRadius.circular(4)),
        child: pw.Text(text, style: pw.TextStyle(font: bold, fontSize: 8.5, color: sev < 0 ? _muted : _sev[sev])),
      );

  pw.Widget h2(String t) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 16, bottom: 8),
        padding: const pw.EdgeInsets.only(bottom: 4),
        decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _gold, width: 1.5))),
        child: pw.Text(t.toUpperCase(), style: pw.TextStyle(font: bold, fontSize: 11, color: _green, letterSpacing: .8)),
      );

  pw.Widget kv(String k, String v) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(children: [
          pw.SizedBox(width: 78, child: pw.Text(k, style: const pw.TextStyle(fontSize: 9.5, color: _muted))),
          pw.Expanded(child: pw.Text(v.isEmpty ? '-' : v, style: pw.TextStyle(font: bold, fontSize: 9.5))),
        ]),
      );

  pw.Widget sectionTable(Section s, int n) {
    final rows = <pw.TableRow>[
      pw.TableRow(decoration: const pw.BoxDecoration(color: _cream), children: [
        pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text('$n. ${s.title.toUpperCase()}', style: pw.TextStyle(font: bold, fontSize: 8.5, color: _green, letterSpacing: .5))),
        pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text('ESTADO', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: bold, fontSize: 8.5, color: _muted))),
      ]),
    ];
    for (final it in s.items) {
      final r = i.results[it.id];
      final o = r?.opt;
      rows.add(pw.TableRow(
        decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _line, width: .5))),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(it.label, style: const pw.TextStyle(fontSize: 9.5)),
              if (r != null && r.nota.isNotEmpty)
                pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 2),
                    child: pw.Text(r.nota, style: const pw.TextStyle(fontSize: 8.5, color: _muted))),
              if (r != null && r.costo != null)
                pw.Text('Costo estimado: ${clp(r.costo!)}', style: const pw.TextStyle(fontSize: 8.5, color: _muted)),
            ]),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: o == null
                  ? pw.Text('No revisado', style: const pw.TextStyle(fontSize: 8.5, color: _muted))
                  : pill(it.opts[o].label, it.opts[o].sev),
            ),
          ),
        ],
      ));
    }
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Table(columnWidths: const {0: pw.FlexColumnWidth(3), 1: pw.FlexColumnWidth(1.3)}, children: rows),
    );
  }

  final doc = pw.Document(title: 'Informe de inspección ${i.vehiculo}', author: 'Atlas Motors');
  doc.addPage(pw.MultiPage(
    pageTheme: pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 30),
      theme: pw.ThemeData.withFont(base: font, bold: bold),
    ),
    footer: (ctx) => pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: _line, width: .5))),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text('Atlas Motors - Folio ${i.folio}', style: const pw.TextStyle(fontSize: 8, color: _muted)),
        pw.Text('Página ${ctx.pageNumber} de ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: _muted)),
      ]),
    ),
    build: (ctx) => [
      // Encabezado
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const pw.BoxDecoration(color: PdfColors.black, border: pw.Border(bottom: pw.BorderSide(color: _gold, width: 3))),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Image(logo, height: 46),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('INFORME DE INSPECCIÓN PRECOMPRA', style: pw.TextStyle(font: bold, fontSize: 10.5, color: _gold300)),
            pw.SizedBox(height: 3),
            pw.Text('Folio ${i.folio}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey300)),
            pw.Text(fecha, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey300)),
          ]),
        ]),
      ),
      pw.SizedBox(height: 16),

      // Vehículo + puntaje
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
        pw.Expanded(
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(i.vehiculo.isEmpty ? 'Vehículo' : i.vehiculo, style: pw.TextStyle(font: bold, fontSize: 20, color: _green)),
            pw.SizedBox(height: 8),
            pw.Wrap(spacing: 6, runSpacing: 4, children: [
              pill('${c[0]} en buen estado', 0),
              pill('${c[1]} con observación', 1),
              pill('${c[2]} con problema', 2),
            ]),
            if (i.recomendacion != null) ...[
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: pw.BoxDecoration(color: _sev[i.recomendacion!], borderRadius: pw.BorderRadius.circular(4)),
                child: pw.Text(recomendaciones[i.recomendacion!].toUpperCase(),
                    style: pw.TextStyle(font: bold, fontSize: 9.5, color: PdfColors.white, letterSpacing: .5)),
              ),
            ],
          ]),
        ),
        if (score != null)
          pw.Container(
            width: 78,
            height: 78,
            decoration: pw.BoxDecoration(color: _green, shape: pw.BoxShape.circle, border: pw.Border.all(color: _gold, width: 4)),
            alignment: pw.Alignment.center,
            child: pw.Column(mainAxisSize: pw.MainAxisSize.min, children: [
              pw.Text('$score', style: pw.TextStyle(font: bold, fontSize: 24, color: _gold300)),
              pw.Text('de 100', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey300)),
            ]),
          ),
      ]),

      h2('Datos de la inspección'),
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Expanded(
          child: pw.Column(children: [
            kv('Marca / Modelo', '${i.marca} ${i.modelo}'.trim()),
            kv('Año', i.anio),
            kv('Patente', i.patente),
            kv('Kilometraje', km == null ? i.km : '${NumberFormat.decimalPattern('es').format(km)} km'),
          ]),
        ),
        pw.SizedBox(width: 20),
        pw.Expanded(
          child: pw.Column(children: [
            kv('Cliente', i.cliente),
            kv('Lugar', i.lugar),
            kv('Fecha', fecha),
            kv('Inspector', i.inspector),
            kv('Modalidad', modalidades[i.modalidad]),
          ]),
        ),
      ]),

      if (i.conclusion.trim().isNotEmpty) ...[
        h2('Conclusión del inspector'),
        pw.Text(i.conclusion.trim(), style: const pw.TextStyle(fontSize: 10, lineSpacing: 2)),
      ],

      if (hallazgos.isNotEmpty) ...[
        h2('Hallazgos principales'),
        pw.Table(
          columnWidths: const {0: pw.FlexColumnWidth(3.2), 1: pw.FlexColumnWidth(1.3), 2: pw.FlexColumnWidth(1.1)},
          children: [
            pw.TableRow(decoration: const pw.BoxDecoration(color: _cream), children: [
              for (final (t, right) in [('PUNTO', false), ('ESTADO', true), ('COSTO ESTIMADO', true)])
                pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(t,
                        textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
                        style: pw.TextStyle(font: bold, fontSize: 8.5, color: _muted))),
            ]),
            for (final h in hallazgos)
              pw.TableRow(
                decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _line, width: .5))),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      pw.Text(h.item.label, style: pw.TextStyle(font: bold, fontSize: 9.5)),
                      pw.Text(h.section.title, style: const pw.TextStyle(fontSize: 8, color: _muted)),
                      if (h.result.nota.trim().isNotEmpty)
                        pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 2),
                            child: pw.Text(h.result.nota.trim(), style: const pw.TextStyle(fontSize: 8.5))),
                    ]),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                    child: pw.Align(alignment: pw.Alignment.topRight, child: pill(h.opt.label, h.opt.sev)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                    child: pw.Text(h.result.costo == null ? '-' : clp(h.result.costo!),
                        textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 9.5)),
                  ),
                ],
              ),
          ],
        ),
        if (i.costoTotal != null)
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 8),
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: pw.BoxDecoration(color: _cream, borderRadius: pw.BorderRadius.circular(4)),
            child: pw.Row(children: [
              pw.Expanded(
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('Reparaciones estimadas', style: pw.TextStyle(font: bold, fontSize: 10, color: _green)),
                  pw.Text('Valores referenciales para negociar con el vendedor; pueden variar según taller y repuestos.',
                      style: const pw.TextStyle(fontSize: 8, color: _muted)),
                ]),
              ),
              pw.Text(clp(i.costoTotal!), style: pw.TextStyle(font: bold, fontSize: 14, color: _green)),
            ]),
          ),
      ],

      h2('Checklist de inspección'),
      for (final (n, s) in checklist.indexed) sectionTable(s, n + 1),

      if (fotos.isNotEmpty) ...[
        h2('Registro fotográfico'),
        pw.Wrap(spacing: 10, runSpacing: 10, children: [
          for (final (img, caption) in fotos)
            pw.SizedBox(
              width: 255,
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.ClipRRect(
                    horizontalRadius: 4, verticalRadius: 4, child: pw.Image(img, width: 255, height: 180, fit: pw.BoxFit.cover)),
                pw.SizedBox(height: 3),
                pw.Text(caption, style: const pw.TextStyle(fontSize: 8, color: _muted)),
              ]),
            ),
        ]),
      ],

      h2('Alcance de la inspección'),
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: _gold, width: 1), borderRadius: pw.BorderRadius.circular(4)),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(
            i.tieneFallasGraves
                ? 'Durante la inspección se detectaron las fallas graves indicadas en este informe.'
                : 'Durante todo el tiempo que duró la inspección, el vehículo no presentó fallas graves.',
            style: pw.TextStyle(font: bold, fontSize: 10, color: _green),
          ),
          pw.SizedBox(height: 6),
          for (final t in alcance)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('•  ', style: const pw.TextStyle(fontSize: 8.5, color: _muted)),
                pw.Expanded(child: pw.Text(t, style: const pw.TextStyle(fontSize: 8.5, lineSpacing: 1.5))),
              ]),
            ),
        ]),
      ),

      pw.SizedBox(height: 26),
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
        pw.Image(shield, height: 40),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Text('Folio ${i.folio}\n${modalidadDetalle[i.modalidad]}',
              style: const pw.TextStyle(fontSize: 8, color: _muted)),
        ),
        pw.SizedBox(width: 20),
        pw.Container(
          width: 170,
          padding: const pw.EdgeInsets.only(top: 5),
          decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey700))),
          child: pw.Text('${i.inspector.isEmpty ? 'Inspector' : i.inspector} - Atlas Motors',
              textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 9)),
        ),
      ]),
    ],
  ));
  return doc.save();
}

/// Texto de alcance y limitación de responsabilidad, según lo que pidió Matías.
/// Conviene que un abogado lo revise antes de usarlo con clientes.
const alcance = [
  'Este informe refleja el estado del vehículo solo en la fecha, hora y lugar de la inspección.',
  'Una inspección precompra no es un diagnóstico mecánico. Es una revisión visual, electrónica (escáner) y en ruta '
      'que busca reducir el riesgo de una mala compra o de una estafa. Un diagnóstico requiere el vehículo en taller '
      'por varias horas (por ejemplo, análisis del fluido de caja, medición de compresión o retiro de bujías).',
  'Atlas Motors no se responsabiliza por fallas que aparezcan después de la inspección, ya que dependen del uso, '
      'la forma de conducir, el estado de los caminos y la frecuencia de mantenimiento que reciba el vehículo.',
  'Los costos de reparación indicados son referenciales y pueden variar según el taller y los repuestos.',
];
