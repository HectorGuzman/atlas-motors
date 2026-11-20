import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../danos.dart';
import '../store.dart';
import '../theme.dart';
import 'section.dart' show tomarFoto;

/// Mapa de daños de la carrocería: el inspector toca la pieza y anota qué
/// tiene. Va arriba en la etapa "Carrocería y pintura".
class MapaDanosCard extends StatefulWidget {
  final Inspection inspection;
  final VoidCallback onChanged;
  const MapaDanosCard({super.key, required this.inspection, required this.onChanged});
  @override
  State<MapaDanosCard> createState() => _MapaDanosCardState();
}

class _MapaDanosCardState extends State<MapaDanosCard> {
  Inspection get i => widget.inspection;
  Mapa get _mapa => mapaDe(i.carroceria);

  void _guardar() {
    Store.I.save(i);
    setState(() {});
    widget.onChanged();
  }

  Future<void> _elegirTipo() async {
    final tipo = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Tipo de vehículo', style: display(19)),
            const SizedBox(height: 12),
            SelectorCarroceria(actual: i.carroceria, onElegir: (t) => Navigator.pop(c, t)),
          ]),
        ),
      ),
    );
    if (tipo == null || tipo == i.carroceria) return;
    if (i.danos.isNotEmpty && i.carroceria.isNotEmpty && mounted) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('¿Cambiar el tipo de vehículo?'),
          content: const Text('Los daños marcados se mantienen y su número pasa al centro de cada pieza en el dibujo nuevo.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Cambiar')),
          ],
        ),
      );
      if (ok != true) return;
    }
    i.carroceria = tipo;
    reubicar(i.danos, mapaDe(tipo));
    _guardar();
  }

  Future<void> _tocar(Offset p, double escala) async {
    final x = p.dx / escala, y = p.dy / escala;
    // ¿Tocó un número? Se edita ese daño.
    for (final d in i.danos.reversed) {
      if (d.ubicado && (Offset(d.x, d.y) - Offset(x, y)).distance <= 12) return _editar(d);
    }
    final m = _mapa;
    final z = m.zonaEn(x, y);
    if (z == null) return;
    HapticFeedback.selectionClick();
    // El número queda donde se tocó (si cayó justo afuera, al centro de la pieza).
    final f = m.formaEn(z, x, y);
    final dentro = f != null && f.contiene(x, y);
    final c = dentro ? P(x, y) : (m.centroDe(z) ?? P(x, y));
    final nuevo = Dano(zona: z, pieza: m.nombres[z] ?? z, tipo: -1, sev: 1, x: c.x, y: c.y);
    final ok = await _hoja(nuevo, nuevo: true);
    if (ok == true) {
      i.danos.add(nuevo);
      _guardar();
    } else {
      // Fotos tomadas en una hoja que se canceló: no quedan colgando.
      await _borrarFotos(nuevo.fotos);
    }
  }

  Future<void> _borrarFotos(Iterable<String> fotos) async {
    for (final f in [...fotos]) {
      await Store.I.removePhoto(i, [f], f);
    }
  }

  Future<void> _editar(Dano d) async {
    HapticFeedback.selectionClick();
    final copia = Dano.fromJson(d.toJson());
    final r = await _hoja(copia, nuevo: false);
    if (r == true) {
      await _borrarFotos(d.fotos.where((f) => !copia.fotos.contains(f)));
      d
        ..tipo = copia.tipo
        ..sev = copia.sev
        ..nota = copia.nota
        ..fotos = copia.fotos;
      _guardar();
    } else if (r == false) {
      await _borrarFotos({...d.fotos, ...copia.fotos});
      i.danos.remove(d);
      _guardar();
    } else {
      await _borrarFotos(copia.fotos.where((f) => !d.fotos.contains(f)));
    }
  }

  /// true = guardar, false = borrar, null = cancelar.
  Future<bool?> _hoja(Dano d, {required bool nuevo}) => showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _HojaDano(inspection: i, dano: d, nuevo: nuevo),
      );

  @override
  Widget build(BuildContext context) {
    final danos = i.danos;
    final elegido = i.carroceria.isNotEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.touch_app_outlined, color: C.green700, size: 22),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Mapa de daños', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: C.green950)),
            ),
            if (danos.isNotEmpty) SevPill('${danos.length} ${danos.length == 1 ? 'marcado' : 'marcados'}', danos.any((d) => d.sev == 2) ? 2 : 1),
          ]),
          const SizedBox(height: 2),
          if (!elegido) ...[
            const Text('Primero elige el tipo de vehículo: el dibujo se arma con su forma.',
                style: TextStyle(color: C.muted, fontSize: 12.5)),
            const SizedBox(height: 12),
            SelectorCarroceria(actual: '', onElegir: (t) {
              i.carroceria = t;
              reubicar(i.danos, mapaDe(t));
              _guardar();
            }),
          ] else ...[
            Row(children: [
              const Expanded(
                child: Text('Toca la pieza donde está el daño. Toca un número para cambiarlo o borrarlo.',
                    style: TextStyle(color: C.muted, fontSize: 12.5)),
              ),
              const SizedBox(width: 8),
              ActionChip(
                avatar: const Icon(Icons.swap_horiz, size: 18, color: C.green700),
                label: Text(tiposCarroceria[i.carroceria]?.$2 ?? i.carroceria),
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, color: C.green900, fontSize: 13),
                backgroundColor: C.cream,
                side: const BorderSide(color: C.line),
                onPressed: _elegirTipo,
              ),
            ]),
            const SizedBox(height: 8),
            LayoutBuilder(builder: (context, c) {
              final escala = min(c.maxWidth / mapaAncho, 640 / mapaAlto);
              final size = Size(mapaAncho * escala, mapaAlto * escala);
              return Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (e) => _tocar(e.localPosition, escala),
                  child: CustomPaint(size: size, painter: MapaPainter(_mapa, danos, escala)),
                ),
              );
            }),
            const SizedBox(height: 8),
            if (danos.isEmpty)
              const Text('Sin daños marcados.', style: TextStyle(color: C.muted, fontSize: 13))
            else
              for (final (n, d) in danos.indexed)
                InkWell(
                  onTap: () => _editar(d),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _Numero(n + 1, d.sev),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(d.nombreZona, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          Text(
                            [d.nombreTipo, gravedades[d.sev]!, if (d.fotos.isNotEmpty) '${d.fotos.length} foto${d.fotos.length == 1 ? '' : 's'}']
                                .join(' · '),
                            style: TextStyle(color: C.sevColor(d.sev), fontSize: 12.5, fontWeight: FontWeight.w600),
                          ),
                          if (d.nota.trim().isNotEmpty)
                            Text(d.nota.trim(), style: const TextStyle(color: C.muted, fontSize: 12.5)),
                        ]),
                      ),
                      const Icon(Icons.chevron_right, color: C.muted, size: 20),
                    ]),
                  ),
                ),
          ],
        ]),
      ),
    );
  }
}

/// Tarjetas con la silueta de cada tipo de vehículo.
class SelectorCarroceria extends StatelessWidget {
  final String actual;
  final ValueChanged<String> onElegir;
  const SelectorCarroceria({super.key, required this.actual, required this.onElegir});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final ancho = (c.maxWidth - 10) / 2;
        return Wrap(spacing: 10, runSpacing: 10, children: [
          for (final MapEntry(key: id, value: (nombre, _)) in tiposCarroceria.entries)
            SizedBox(
              width: ancho,
              child: Material(
                color: id == actual ? C.cream : Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onElegir(id);
                  },
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: id == actual ? C.gold : C.line, width: id == actual ? 2 : 1.3),
                    ),
                    child: Column(children: [
                      AspectRatio(aspectRatio: 312 / 116, child: CustomPaint(painter: SiluetaPainter(mapaDe(id)))),
                      const SizedBox(height: 6),
                      Text(nombre,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: C.green950, height: 1.15)),
                    ]),
                  ),
                ),
              ),
            ),
        ]);
      });
}

class _Numero extends StatelessWidget {
  final int n, sev;
  const _Numero(this.n, this.sev);
  @override
  Widget build(BuildContext context) => Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: C.sevColor(sev), shape: BoxShape.circle),
        child: Text('$n', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
      );
}

/// Hoja para anotar un daño: tipo, gravedad, comentario y fotos.
class _HojaDano extends StatefulWidget {
  final Inspection inspection;
  final Dano dano;
  final bool nuevo;
  const _HojaDano({required this.inspection, required this.dano, required this.nuevo});
  @override
  State<_HojaDano> createState() => _HojaDanoState();
}

class _HojaDanoState extends State<_HojaDano> {
  Dano get d => widget.dano;
  late final _nota = TextEditingController(text: d.nota);
  bool _gravedadElegida = false;

  @override
  void initState() {
    super.initState();
    _gravedadElegida = !widget.nuevo;
  }

  @override
  void dispose() {
    _nota.dispose();
    super.dispose();
  }

  Future<void> _foto() async {
    final f = await tomarFoto(context, widget.inspection);
    if (f != null) setState(() => d.fotos.add(f));
  }

  @override
  Widget build(BuildContext context) {
    final listo = d.tipo >= 0;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.nombreZona, style: display(19)),
            const SizedBox(height: 14),
            const Text('¿Qué tiene?', style: TextStyle(fontWeight: FontWeight.w700, color: C.muted, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (var t = 0; t < tiposDano.length; t++)
                ChoiceChip(
                  label: Text(tiposDano[t]),
                  selected: d.tipo == t,
                  showCheckmark: false,
                  labelStyle: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14, color: d.tipo == t ? Colors.white : C.text),
                  selectedColor: C.green800,
                  backgroundColor: Colors.white,
                  side: BorderSide(color: d.tipo == t ? C.green800 : C.line, width: 1.3),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  onSelected: (_) => setState(() {
                    d.tipo = t;
                    if (!_gravedadElegida) d.sev = gravedadSugerida[t];
                  }),
                ),
            ]),
            const SizedBox(height: 16),
            const Text('Gravedad', style: TextStyle(fontWeight: FontWeight.w700, color: C.muted, fontSize: 13)),
            const SizedBox(height: 8),
            Row(children: [
              for (final g in [1, 2]) ...[
                if (g == 2) const SizedBox(width: 8),
                Expanded(
                  child: Material(
                    color: d.sev == g ? C.sev[g] : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() {
                        d.sev = g;
                        _gravedadElegida = true;
                      }),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 48),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: d.sev == g ? C.sev[g] : C.line, width: 1.5),
                        ),
                        child: Text(g == 1 ? 'Detalle' : 'Importante',
                            style: TextStyle(fontWeight: FontWeight.w700, color: d.sev == g ? Colors.white : C.text)),
                      ),
                    ),
                  ),
                ),
              ],
            ]),
            const SizedBox(height: 14),
            TextField(
              controller: _nota,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Comentario (opcional): tamaño, si se nota, etc.', isDense: true),
              onChanged: (v) => d.nota = v,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 72,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                for (final f in d.fotos) ...[
                  Stack(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(Store.I.photoFile(f), width: 96, height: 72, fit: BoxFit.cover, cacheWidth: 288,
                          errorBuilder: (_, _, _) => Container(width: 96, height: 72, color: C.cream2)),
                    ),
                    Positioned(
                      right: 2,
                      top: 2,
                      child: GestureDetector(
                        // El archivo se borra al guardar (si se cancela, la foto vuelve).
                        onTap: () => setState(() => d.fotos.remove(f)),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 15, color: Colors.white),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(width: 8),
                ],
                InkWell(
                  onTap: _foto,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 96,
                    height: 72,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10), border: Border.all(color: C.line, width: 1.5)),
                    child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add_a_photo_outlined, color: C.green700),
                      SizedBox(height: 3),
                      Text('Foto', style: TextStyle(color: C.green700, fontWeight: FontWeight.w600, fontSize: 12.5)),
                    ]),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: GoldButton(widget.nuevo ? 'Marcar daño' : 'Guardar cambios',
                  icon: Icons.check, onPressed: listo ? () => Navigator.pop(context, true) : null),
            ),
            // El aviso ocupa siempre su espacio: así el botón no se mueve al elegir.
            if (widget.nuevo)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Center(
                  child: Text(listo ? ' ' : 'Elige qué tiene para marcarlo.',
                      style: const TextStyle(color: C.muted, fontSize: 12.5)),
                ),
              ),
            if (!widget.nuevo)
              Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Borrar este daño'),
                  style: TextButton.styleFrom(foregroundColor: C.bad),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

Path _path(Forma f, double k) {
  final p = Path();
  for (final (c, ps) in f.cmds) {
    switch (c) {
      case Cmd.m:
        p.moveTo(ps[0].x * k, ps[0].y * k);
      case Cmd.l:
        p.lineTo(ps[0].x * k, ps[0].y * k);
      case Cmd.c:
        p.cubicTo(ps[0].x * k, ps[0].y * k, ps[1].x * k, ps[1].y * k, ps[2].x * k, ps[2].y * k);
      case Cmd.z:
        p.close();
    }
  }
  return p;
}

void _pintarPieza(Canvas canvas, Pieza p, double k, int? grav) {
  final (fill, stroke, w) = estilos[p.estilo]!;
  final path = _path(p.forma, k);
  final rueda = p.estilo == 'llanta';
  if (fill != null && !p.forma.abierta) {
    canvas.drawPath(path, Paint()..color = grav != null && !rueda ? C.sevBg[grav] : Color(fill));
  }
  if (grav != null) {
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (rueda ? 3 : 1.8) * k
      ..color = C.sev[grav]);
  } else if (stroke != null) {
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Color(stroke));
  }
}

/// Dibuja el vehículo desplegado, las piezas con daño teñidas y los números.
class MapaPainter extends CustomPainter {
  final Mapa mapa;
  final List<Dano> danos;
  final double escala;
  MapaPainter(this.mapa, this.danos, this.escala);

  @override
  void paint(Canvas canvas, Size size) {
    final k = escala;
    final grav = gravedadPorZona(danos);
    for (final p in mapa.piezas) {
      _pintarPieza(canvas, p, k, p.zona == null ? null : grav[p.zona]);
    }
    for (final t in mapa.textos) {
      final tp = TextPainter(
        text: TextSpan(
            text: t.t,
            style: TextStyle(color: C.muted, fontSize: t.tam * k, fontWeight: FontWeight.w700, letterSpacing: .6 * k)),
        textDirection: TextDirection.ltr,
      )..layout();
      final dx = switch (t.ancla) { 'c' => tp.width / 2, 'd' => tp.width, _ => 0.0 };
      tp.paint(canvas, Offset(t.x * k - dx, t.y * k - tp.height / 2));
    }
    for (final (n, d) in danos.indexed) {
      if (!d.ubicado) continue;
      final c = Offset(d.x * k, d.y * k);
      canvas.drawCircle(c + Offset(0, .8 * k), 9.5 * k, Paint()..color = Colors.black.withValues(alpha: .18));
      canvas.drawCircle(c, 9.5 * k, Paint()..color = Colors.white);
      canvas.drawCircle(c, 8 * k, Paint()..color = C.sev[d.sev]);
      final tp = TextPainter(
        text: TextSpan(text: '${n + 1}', style: TextStyle(color: Colors.white, fontSize: 9.5 * k, fontWeight: FontWeight.w800)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(MapaPainter old) => true;
}

/// Solo el costado derecho, para el selector de tipo de vehículo.
class SiluetaPainter extends CustomPainter {
  final Mapa mapa;
  SiluetaPainter(this.mapa);

  @override
  void paint(Canvas canvas, Size size) {
    // Se ajusta al costado derecho de este vehículo (cada tipo tiene su largo).
    var l = double.infinity, t = double.infinity, r = -double.infinity, b = -double.infinity;
    for (final p in mapa.piezas) {
      if (p.vista != 'der') continue;
      final (pl, pt, pr, pb) = p.forma.caja;
      l = min(l, pl);
      t = min(t, pt);
      r = max(r, pr);
      b = max(b, pb);
    }
    // Escala común para todos los tipos: así se nota que una camioneta es más larga que un hatchback.
    final k = min(size.width / 312, size.height / (b - t + 4));
    canvas.translate(size.width / 2 - (l + r) / 2 * k, size.height - b * k - 1);
    for (final p in mapa.piezas) {
      if (p.vista == 'der') _pintarPieza(canvas, p, k, null);
    }
  }

  @override
  bool shouldRepaint(SiluetaPainter old) => old.mapa != mapa;
}
