import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../checklist.dart';
import '../danos.dart';
import '../messages.dart';
import '../store.dart';
import '../theme.dart' show clp, GoldButton;
import 'videos.dart' show duracion, puntoDe;

/// Vista previa del informe, con botón para mandarlo al cliente (WhatsApp,
/// correo, etc.) junto con un mensaje de despedida.
class ReportScreen extends StatefulWidget {
  final Inspection inspection;
  const ReportScreen({super.key, required this.inspection});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  Inspection get inspection => widget.inspection;
  late final Future<Uint8List> _pdf = buildReport(inspection);
  bool _enviando = false;

  String get _nombre => 'Informe ${inspection.vehiculo} ${inspection.patente}'.trim().replaceAll(RegExp(r'\s+'), ' ');

  Future<void> _enviar(BuildContext bc) async {
    setState(() => _enviando = true);
    try {
      final bytes = await _pdf;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${_nombre.replaceAll('/', '-')}.pdf');
      await file.writeAsBytes(bytes);
      final texto = mensajeInforme(inspection);
      // Algunas apps (WhatsApp con documentos) no siempre muestran el texto:
      // queda copiado para pegarlo si hace falta.
      await Clipboard.setData(ClipboardData(text: texto));
      if (!bc.mounted) return;
      final box = bc.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(ShareParams(
        text: texto,
        files: [XFile(file.path, mimeType: 'application/pdf')],
        sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('El mensaje quedó copiado: si WhatsApp no lo muestra junto al PDF, pégalo en el chat.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo preparar el informe: $e')));
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final faltan = Store.I.fotosFaltantes(inspection);
    return Scaffold(
      appBar: AppBar(title: const Text('Informe')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Builder(
            builder: (bc) => GoldButton(_enviando ? 'Preparando…' : 'Enviar informe al cliente',
                icon: Icons.send_outlined, onPressed: _enviando ? null : () => _enviar(bc)),
          ),
        ),
      ),
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
        Expanded(
          child: PdfPreview(
            build: (_) => _pdf,
            pdfFileName: '$_nombre.pdf',
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            allowPrinting: false,
            allowSharing: false,
            loadingWidget: const CircularProgressIndicator(),
          ),
        ),
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

/// Datos de la empresa que van en el encabezado de los PDF.
const _empresa = [
  'Atlas Motors Chile SpA',
  'RUT 78.422.947-5',
  'La Serena, Coquimbo',
  '+56 9 3559 5554',
  'servicios.atlasmotors@gmail.com',
  'atlasmotors.cl',
];

/// Franja negra de arriba: logo y título del documento, y abajo los datos
/// de la empresa en una línea.
pw.Widget _encabezado(pw.MemoryImage logo, pw.Font bold, String titulo, List<String> lineas) => pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(16, 10, 16, 7),
      decoration: const pw.BoxDecoration(color: PdfColors.black, border: pw.Border(bottom: pw.BorderSide(color: _gold, width: 3))),
      child: pw.Column(children: [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Image(logo, height: 46),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text(titulo, style: pw.TextStyle(font: bold, fontSize: 10.5, color: _gold300)),
            pw.SizedBox(height: 3),
            for (final l in lineas) pw.Text(l, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey300)),
          ]),
        ]),
        pw.Container(
          margin: const pw.EdgeInsets.only(top: 7),
          padding: const pw.EdgeInsets.only(top: 5),
          decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey800, width: .5))),
          child: pw.Text(_empresa.join(' · '),
              textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey400)),
        ),
      ]),
    );

/// El mapa de daños dibujado en el PDF, de [ancho] puntos de ancho.
pw.Widget _mapaPdf(Mapa mapa, List<Dano> danos, double ancho, pw.Font bold) {
  final k = ancho / mapaAncho;
  final alto = mapaAlto * k;
  final grav = gravedadPorZona(danos);

  // El PDF mide desde abajo: se da vuelta el eje vertical.
  void trazar(PdfGraphics g, Forma f) {
    for (final (c, ps) in f.cmds) {
      switch (c) {
        case Cmd.m:
          g.moveTo(ps[0].x * k, alto - ps[0].y * k);
        case Cmd.l:
          g.lineTo(ps[0].x * k, alto - ps[0].y * k);
        case Cmd.c:
          g.curveTo(ps[0].x * k, alto - ps[0].y * k, ps[1].x * k, alto - ps[1].y * k, ps[2].x * k, alto - ps[2].y * k);
        case Cmd.z:
          g.closePath();
      }
    }
  }

  pw.Widget texto(Texto t) {
    const w = 120.0;
    final left = switch (t.ancla) { 'c' => t.x * k - w / 2, 'd' => t.x * k - w, _ => t.x * k };
    return pw.Positioned(
      left: left,
      top: t.y * k - t.tam * k * .7,
      child: pw.SizedBox(
        width: w,
        child: pw.Text(t.t,
            textAlign: switch (t.ancla) { 'c' => pw.TextAlign.center, 'd' => pw.TextAlign.right, _ => pw.TextAlign.left },
            style: pw.TextStyle(font: bold, fontSize: t.tam * k, color: _muted, letterSpacing: .4)),
      ),
    );
  }

  final r = 8.5 * k;
  return pw.SizedBox(
    width: ancho,
    height: alto,
    child: pw.Stack(children: [
      pw.CustomPaint(
        size: PdfPoint(ancho, alto),
        painter: (g, _) {
          for (final p in mapa.piezas) {
            final (fill, stroke, w) = estilos[p.estilo]!;
            final s = p.zona == null ? null : grav[p.zona];
            final rueda = p.estilo == 'llanta';
            final relleno = p.forma.abierta ? null : (s != null && !rueda ? _sevBg[s] : (fill == null ? null : PdfColor.fromInt(fill)));
            final borde = s != null ? _sev[s] : (stroke == null ? null : PdfColor.fromInt(stroke));
            if (relleno != null) {
              g.setFillColor(relleno);
              trazar(g, p.forma);
              g.fillPath();
            }
            if (borde != null) {
              g
                ..setStrokeColor(borde)
                ..setLineWidth((s != null ? (rueda ? 3 : 1.8) : w) * k)
                ..setLineCap(PdfLineCap.round)
                ..setLineJoin(PdfLineJoin.round);
              trazar(g, p.forma);
              g.strokePath();
            }
          }
          for (final d in danos) {
            if (!d.ubicado) continue;
            final cx = d.x * k, cy = alto - d.y * k;
            g
              ..setFillColor(PdfColors.white)
              ..drawEllipse(cx, cy, r + 1.2, r + 1.2)
              ..fillPath()
              ..setFillColor(_sev[d.sev])
              ..drawEllipse(cx, cy, r, r)
              ..fillPath();
          }
        },
      ),
      for (final t in mapa.textos) texto(t),
      for (final (n, d) in danos.indexed)
        if (d.ubicado)
          pw.Positioned(
            left: d.x * k - r,
            top: d.y * k - r,
            child: pw.SizedBox(
              width: r * 2,
              height: r * 2,
              child: pw.Center(
                  child: pw.Text('${n + 1}', style: pw.TextStyle(font: bold, fontSize: 7.5, color: PdfColors.white))),
            ),
          ),
    ]),
  );
}

/// Sección del mapa de daños: el dibujo y, al lado, la lista numerada.
List<pw.Widget> _seccionDanos(Inspection i, pw.Widget titulo, pw.Font bold, {double ancho = 230}) {
  final danos = i.danos;
  final mapa = mapaDe(i.carroceria);
  pw.Widget fila(int n, Dano d) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 7),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Container(
            width: 15,
            height: 15,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(color: _sev[d.sev], shape: pw.BoxShape.circle),
            child: pw.Text('$n', style: pw.TextStyle(font: bold, fontSize: 7.5, color: PdfColors.white)),
          ),
          pw.SizedBox(width: 7),
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(d.nombreZona, style: pw.TextStyle(font: bold, fontSize: 9.5)),
              pw.Text('${d.nombreTipo} · ${gravedades[d.sev]}', style: pw.TextStyle(font: bold, fontSize: 8.5, color: _sev[d.sev])),
              if (d.nota.trim().isNotEmpty) pw.Text(d.nota.trim(), style: const pw.TextStyle(fontSize: 8.5, color: _muted)),
            ]),
          ),
        ]),
      );
  const alLado = 12;
  final lista = <pw.Widget>[
    if (tiposCarroceria[i.carroceria] != null)
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text('Vehículo: ${tiposCarroceria[i.carroceria]!.$1}', style: pw.TextStyle(font: bold, fontSize: 9.5, color: _green)),
      ),
    if (danos.isEmpty)
      pw.Text('No se encontraron daños en la carrocería durante la inspección visual 360°.',
          style: pw.TextStyle(font: bold, fontSize: 10, color: _sev[0]))
    else ...[
      pw.Text('Piezas con daño, numeradas como en el dibujo. Ámbar: detalle; rojo: importante.',
          style: const pw.TextStyle(fontSize: 8.5, color: _muted)),
      pw.SizedBox(height: 8),
      for (final (n, d) in danos.take(alLado).indexed) fila(n + 1, d),
    ],
  ];
  return [
    pw.Inseparable(
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        titulo,
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          _mapaPdf(mapa, danos, ancho, bold),
          pw.SizedBox(width: 18),
          pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: lista)),
        ]),
      ]),
    ),
    for (final (n, d) in danos.skip(alLado).indexed) fila(n + alLado + 1, d),
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
  for (final (n, d) in i.danos.indexed) {
    for (final f in d.fotos) {
      final bytes = await fotoParaPdf(f);
      if (bytes != null) fotos.add((pw.MemoryImage(bytes), 'Daño ${n + 1}: ${d.nombreZona} · ${d.nombreTipo}'));
    }
  }
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
      _encabezado(logo, bold, 'INFORME DE INSPECCIÓN PRECOMPRA', ['Folio ${i.folio}', fecha]),
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

      if (i.danos.isNotEmpty || i.carroceria.isNotEmpty)
        ..._seccionDanos(i, h2('Mapa de daños de carrocería'), bold),

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
    for (final (n, d) in i.danos.indexed)
      for (final f in d.fotos) f: 'Daño ${n + 1}: ${d.nombreZona} · ${d.nombreTipo}',
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
      _encabezado(logo, bold, 'FICHA DE INSPECCIÓN · AUTO EN VENTA', ['Inspeccionado el $fecha']),
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
      if (i.danos.isNotEmpty || i.carroceria.isNotEmpty)
        ..._seccionDanos(i, h2('Mapa de daños de carrocería'), bold),
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
