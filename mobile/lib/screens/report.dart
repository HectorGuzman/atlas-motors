import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../checklist.dart';
import '../store.dart';
import '../theme.dart' show clp;
import 'videos.dart' show duracion, puntoDe;

/// Vista previa del informe, con botón para compartir (WhatsApp, correo, etc.).
class ReportScreen extends StatelessWidget {
  final Inspection inspection;
  const ReportScreen({super.key, required this.inspection});

  @override
  Widget build(BuildContext context) {
    final name = 'Informe ${inspection.vehiculo} ${inspection.patente}'.trim().replaceAll(RegExp(r'\s+'), ' ');
    final faltan = Store.I.fotosFaltantes(inspection);
    return Scaffold(
      appBar: AppBar(title: const Text('Informe')),
      body: Column(children: [
        if (faltan > 0)
          Container(
            width: double.infinity,
            color: const Color(0xFFFFF3D6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              faltan == 1
                  ? 'Falta 1 foto por descargar a este teléfono: no aparece en el informe. Revisa tu señal y vuelve a abrirlo.'
                  : 'Faltan $faltan fotos por descargar a este teléfono: no aparecen en el informe. Revisa tu señal y vuelve a abrirlo.',
              style: const TextStyle(color: Color(0xFF8A5A00), fontSize: 13),
            ),
          ),
        Expanded(child: PdfPreview(
        build: (_) => buildReport(inspection),
        pdfFileName: '$name.pdf',
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        allowPrinting: false,
        loadingWidget: const CircularProgressIndicator(),
      )),
      ]),
    );
  }
}

/// La foto en el informe mide ~9 cm de ancho. Se guarda la versión
/// reducida para no recomprimir cada vez que se abre el informe.
Future<Uint8List?> fotoParaPdf(String name) async {
  final original = Store.I.photoFile(name);
  if (!await original.exists()) return null;
  final reducida = Store.I.photoPdfFile(name);
  try {
    if (!await reducida.exists()) {
      await reducida.parent.create(recursive: true);
      // El lado corto queda en 700 px (ej. 1600x1200 -> 933x700): nítida a ese tamaño.
      await FlutterImageCompress.compressAndGetFile(original.path, reducida.path,
          minWidth: 700, minHeight: 700, quality: 60, keepExif: false);
    }
    if (await reducida.exists()) return await reducida.readAsBytes();
  } catch (e) {
    debugPrint('No se pudo reducir $name: $e');
  }
  return original.readAsBytes();
}

const _green = PdfColor.fromInt(0xFF0B2418);
const _gold = PdfColor.fromInt(0xFFD4A62A);
const _gold300 = PdfColor.fromInt(0xFFF3D36B);
const _cream = PdfColor.fromInt(0xFFF7F3E8);
const _muted = PdfColor.fromInt(0xFF5F6862);
const _line = PdfColor.fromInt(0xFFE4DFD1);
const _sev = [PdfColor.fromInt(0xFF1F8A4C), PdfColor.fromInt(0xFFC98A06), PdfColor.fromInt(0xFFC0392B)];
const _sevBg = [PdfColor.fromInt(0xFFE3F4EA), PdfColor.fromInt(0xFFFFF3D6), PdfColor.fromInt(0xFFFDE4E1)];

/// Fotos de a dos por fila. El título va pegado a la primera fila para que no
/// quede solo al final de una página.
List<pw.Widget> _fotosEnFilas(pw.Widget titulo, List<(pw.MemoryImage, String)> fotos) {
  pw.Widget foto((pw.MemoryImage, String) f) => pw.SizedBox(
        width: 255,
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.ClipRRect(horizontalRadius: 4, verticalRadius: 4, child: pw.Image(f.$1, width: 255, height: 180, fit: pw.BoxFit.cover)),
          if (f.$2.isNotEmpty) ...[
            pw.SizedBox(height: 3),
            pw.Text(f.$2, style: const pw.TextStyle(fontSize: 8, color: _muted)),
          ],
        ]),
      );
  final filas = <pw.Widget>[
    for (var k = 0; k < fotos.length; k += 2)
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          foto(fotos[k]),
          if (k + 1 < fotos.length) ...[pw.SizedBox(width: 10), foto(fotos[k + 1])],
        ]),
      ),
  ];
  if (filas.isEmpty) return [];
  return [
    pw.Inseparable(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [titulo, filas.first])),
    ...filas.skip(1),
  ];
}

/// Videos en el informe: miniatura, qué muestra y un QR (y enlace) para verlo.
/// Un PDF no reproduce video, así que se abre en el navegador del cliente.
Future<List<pw.Widget>> _videosPdf(Inspection i, pw.Widget titulo, pw.Font bold) async {
  final filas = <pw.Widget>[];
  for (final v in i.videos) {
    final mini = await fotoParaPdf(v.miniatura);
    final punto = puntoDe(v);
    filas.add(pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: _line), borderRadius: pw.BorderRadius.circular(4)),
      child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
        pw.SizedBox(
          width: 110,
          height: 72,
          child: pw.Stack(alignment: pw.Alignment.center, children: [
            if (mini != null)
              pw.ClipRRect(
                  horizontalRadius: 3,
                  verticalRadius: 3,
                  child: pw.Image(pw.MemoryImage(mini), width: 110, height: 72, fit: pw.BoxFit.cover))
            else
              pw.Container(width: 110, height: 72, color: _green),
            pw.Container(
              width: 24,
              height: 24,
              decoration: const pw.BoxDecoration(color: PdfColor(0, 0, 0, .55), shape: pw.BoxShape.circle),
              child: pw.Center(
                child: pw.CustomPaint(
                  size: const PdfPoint(9, 10),
                  painter: (canvas, size) => canvas
                    ..setFillColor(PdfColors.white)
                    ..moveTo(1, 0)
                    ..lineTo(1, size.y)
                    ..lineTo(size.x, size.y / 2)
                    ..closePath()
                    ..fillPath(),
                ),
              ),
            ),
          ]),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(v.nota.trim().isEmpty ? 'Video de la inspección' : v.nota.trim(),
                style: pw.TextStyle(font: bold, fontSize: 9.5, color: _green)),
            pw.SizedBox(height: 2),
            pw.Text([?punto, duracion(v.segundos)].join(' · '), style: const pw.TextStyle(fontSize: 8.5, color: _muted)),
            pw.SizedBox(height: 4),
            if (v.url != null)
              pw.UrlLink(
                destination: v.url!,
                child: pw.Text('Ver video',
                    style: pw.TextStyle(font: bold, fontSize: 8.5, color: _gold, decoration: pw.TextDecoration.underline)),
              )
            else
              pw.Text('Video pendiente de subir: vuelve a generar el informe cuando haya señal.',
                  style: const pw.TextStyle(fontSize: 8, color: _muted)),
          ]),
        ),
        if (v.url != null) ...[
          pw.SizedBox(width: 10),
          pw.UrlLink(
            destination: v.url!,
            child: pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: v.url!, width: 64, height: 64, color: _green),
          ),
        ],
      ]),
    ));
  }
  if (filas.isEmpty) return [];
  return [
    pw.Inseparable(
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        titulo,
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Text('Escanea el código o toca "Ver video" para verlo con sonido.',
              style: const pw.TextStyle(fontSize: 8.5, color: _muted)),
        ),
        filas.first,
      ]),
    ),
    ...filas.skip(1),
  ];
}

Future<Uint8List> buildReport(Inspection i) async {
  final logo = pw.MemoryImage((await rootBundle.load('assets/logo-wordmark.jpg')).buffer.asUint8List());
  final shield = pw.MemoryImage((await rootBundle.load('assets/logo-shield.jpg')).buffer.asUint8List());
  // Letras incluidas en la app: el PDF se genera sin internet.
  final font = pw.Font.ttf(await rootBundle.load('assets/google_fonts/Inter-Regular.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/google_fonts/Inter-Bold.ttf'));
  final fecha = DateFormat("d 'de' MMMM 'de' y", 'es').format(i.fecha);
  final km = int.tryParse(i.km);
  final c = i.counts();
  final score = i.score;
  final hallazgos = i.hallazgos;

  // Fotos con su leyenda (sección y punto), reducidas para que el PDF sea liviano.
  final fotos = <(pw.MemoryImage, String)>[];
  for (final s in checklist) {
    for (final it in s.items) {
      for (final f in i.results[it.id]?.fotos ?? const <String>[]) {
        final bytes = await fotoParaPdf(f);
        if (bytes != null) fotos.add((pw.MemoryImage(bytes), '${s.title}: ${it.label}'));
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

  final videos = await _videosPdf(i, h2('Videos'), bold);

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

      ..._fotosEnFilas(h2('Registro fotográfico'), fotos),

      ...videos,

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

/// Ficha de inspección para el marketplace: resumen público del informe.
/// Va con las fotos que eligió el vendedor, pero los puntos con observación
/// o problema se muestran siempre (como texto), para que el comprador confíe
/// en el sello de Atlas Motors. No incluye patente ni datos del dueño.
/// [marcar] recibe la foto reducida y devuelve la versión con marca de agua
/// (la ficha es pública: va al marketplace).
Future<Uint8List> buildFicha(Inspection i, {Future<Uint8List> Function(Uint8List)? marcar}) async {
  final v = i.venta!;
  final logo = pw.MemoryImage((await rootBundle.load('assets/logo-wordmark.jpg')).buffer.asUint8List());
  final shield = pw.MemoryImage((await rootBundle.load('assets/logo-shield.jpg')).buffer.asUint8List());
  final font = pw.Font.ttf(await rootBundle.load('assets/google_fonts/Inter-Regular.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/google_fonts/Inter-Bold.ttf'));
  final fecha = DateFormat("d 'de' MMMM 'de' y", 'es').format(i.fecha);
  final km = int.tryParse(i.km);
  final c = i.counts();
  final score = i.score;
  final hallazgos = i.hallazgos;

  final leyendas = <String, String>{
    for (final s in checklist)
      for (final it in s.items)
        for (final f in i.results[it.id]?.fotos ?? const <String>[]) f: '${s.title}: ${it.label}',
  };
  final fotos = <(pw.MemoryImage, String)>[];
  for (final f in v.fotos) {
    var bytes = await fotoParaPdf(f);
    if (bytes != null && marcar != null) bytes = await marcar(bytes);
    if (bytes != null) fotos.add((pw.MemoryImage(bytes), leyendas[f] ?? ''));
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
  pw.Widget cell(String t, {bool b = false, bool right = false, PdfColor? color}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: pw.Text(t,
            textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
            style: pw.TextStyle(font: b ? bold : font, fontSize: 9, color: color)),
      );

  final datos = [
    if (i.anio.isNotEmpty) i.anio,
    if (km != null) '${NumberFormat.decimalPattern('es').format(km)} km',
    if (v.combustible.isNotEmpty) v.combustible,
    if (v.transmision.isNotEmpty) v.transmision,
    if (v.comuna.isNotEmpty) v.comuna,
  ].join('  ·  ');

  final doc = pw.Document(title: 'Ficha de inspección ${i.vehiculo}', author: 'Atlas Motors');
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
        pw.Text('Atlas Motors - atlasmotors.cl - Inspección ${i.folio}', style: const pw.TextStyle(fontSize: 8, color: _muted)),
        pw.Text('Página ${ctx.pageNumber} de ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: _muted)),
      ]),
    ),
    build: (ctx) => [
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const pw.BoxDecoration(color: PdfColors.black, border: pw.Border(bottom: pw.BorderSide(color: _gold, width: 3))),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Image(logo, height: 46),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('FICHA DE INSPECCIÓN · AUTO EN VENTA', style: pw.TextStyle(font: bold, fontSize: 10.5, color: _gold300)),
            pw.SizedBox(height: 3),
            pw.Text('Inspeccionado el $fecha', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey300)),
          ]),
        ]),
      ),
      pw.SizedBox(height: 16),
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
        pw.Expanded(
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(i.vehiculo, style: pw.TextStyle(font: bold, fontSize: 20, color: _green)),
            if (datos.isNotEmpty) pw.Padding(
                padding: const pw.EdgeInsets.only(top: 3),
                child: pw.Text(datos, style: const pw.TextStyle(fontSize: 10, color: _muted))),
            if (v.precio != null) pw.Padding(
                padding: const pw.EdgeInsets.only(top: 6),
                child: pw.Text(clp(v.precio!), style: pw.TextStyle(font: bold, fontSize: 16, color: _green))),
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
      if (v.comentario.trim().isNotEmpty) ...[
        h2('Comentario del inspector'),
        pw.Text(v.comentario.trim(), style: const pw.TextStyle(fontSize: 10, lineSpacing: 2)),
      ],
      if (v.descripcion.trim().isNotEmpty) ...[
        h2('Descripción del vendedor'),
        pw.Text(v.descripcion.trim(), style: const pw.TextStyle(fontSize: 10, lineSpacing: 2)),
      ],
      h2('Resumen por etapa'),
      pw.Table(
        columnWidths: const {0: pw.FlexColumnWidth(3), 1: pw.FlexColumnWidth(1), 2: pw.FlexColumnWidth(1), 3: pw.FlexColumnWidth(1)},
        children: [
          pw.TableRow(decoration: const pw.BoxDecoration(color: _cream), children: [
            cell('ETAPA', b: true, color: _muted),
            cell('BIEN', b: true, right: true, color: _sev[0]),
            cell('OBS.', b: true, right: true, color: _sev[1]),
            cell('PROBLEMA', b: true, right: true, color: _sev[2]),
          ]),
          for (final s in checklist)
            if (i.answeredIn(s) > 0)
              pw.TableRow(
                decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _line, width: .5))),
                children: [
                  cell(s.title),
                  for (final n in i.counts(s)) cell(n == 0 ? '-' : '$n', right: true),
                ],
              ),
        ],
      ),
      h2('Puntos a considerar'),
      if (hallazgos.isEmpty)
        pw.Text('El inspector no registró observaciones ni problemas.', style: const pw.TextStyle(fontSize: 10))
      else
        pw.Table(
          columnWidths: const {0: pw.FlexColumnWidth(3), 1: pw.FlexColumnWidth(1.4)},
          children: [
            for (final h in hallazgos)
              pw.TableRow(
                decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _line, width: .5))),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      pw.Text(h.item.label, style: pw.TextStyle(font: bold, fontSize: 9.5)),
                      pw.Text(h.section.title, style: const pw.TextStyle(fontSize: 8, color: _muted)),
                    ]),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                    child: pw.Align(alignment: pw.Alignment.topRight, child: pill(h.opt.label, h.opt.sev)),
                  ),
                ],
              ),
          ],
        ),
      ..._fotosEnFilas(h2('Fotos'), fotos),
      h2('Sobre esta ficha'),
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: _gold, width: 1), borderRadius: pw.BorderRadius.circular(4)),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          for (final t in [
            'Resumen de la inspección precompra que Atlas Motors le hizo a este vehículo el $fecha. '
                'Muestra todos los puntos con observación o problema; las fotos las eligió el vendedor.',
            'El precio y la descripción del vendedor son responsabilidad del vendedor.',
            ...alcance.where((t) => !t.startsWith('Los costos')).map((t) => t.replaceFirst('Este informe', 'Esta ficha')),
          ])
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('•  ', style: const pw.TextStyle(fontSize: 8.5, color: _muted)),
                pw.Expanded(child: pw.Text(t, style: const pw.TextStyle(fontSize: 8.5, lineSpacing: 1.5))),
              ]),
            ),
        ]),
      ),
      pw.SizedBox(height: 18),
      pw.Row(children: [
        pw.Image(shield, height: 36),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Text('¿Te interesa este auto? Escríbenos por WhatsApp al +56 9 3559 5554 o visita atlasmotors.cl',
              style: pw.TextStyle(font: bold, fontSize: 9.5, color: _green)),
        ),
      ]),
    ],
  ));
  return doc.save();
}
