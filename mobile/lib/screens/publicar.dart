import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../checklist.dart';
import '../marketplace.dart';
import '../messages.dart';
import '../store.dart';
import '../theme.dart';
import 'garage.dart';
import 'videos.dart';

/// Publicar el auto inspeccionado en el marketplace de atlasmotors.cl.
/// Para cuando el dueño pide la inspección porque lo quiere vender.
class PublicarScreen extends StatefulWidget {
  final Inspection inspection;
  const PublicarScreen({super.key, required this.inspection});
  @override
  State<PublicarScreen> createState() => _PublicarScreenState();
}

class _PublicarScreenState extends State<PublicarScreen> {
  Inspection get i => widget.inspection;
  late final Venta v = i.venta ??= _nueva();
  late final _precio = TextEditingController(text: v.precio?.toString() ?? '');
  late final _comuna = TextEditingController(text: v.comuna);
  late final _descripcion = TextEditingController(text: v.descripcion);
  late final _comentario = TextEditingController(text: v.comentario);
  String? _avance; // mientras publica

  /// Primera vez: comuna de la inspección, comentario = conclusión, y de portada
  /// las fotos de carrocería de puntos sin problemas.
  Venta _nueva() {
    final carroceria = checklist.firstWhere((s) => s.id == 'carroceria');
    return Venta(
      comuna: i.lugar,
      comentario: i.conclusion,
      fotos: [
        for (final it in carroceria.items)
          if ((_sevDe(it) ?? 0) <= 0) ...?i.results[it.id]?.fotos,
      ],
    );
  }

  int? _sevDe(Item it) {
    final o = i.results[it.id]?.opt;
    return o == null || o >= it.opts.length ? null : it.opts[o].sev;
  }

  @override
  void dispose() {
    _precio.dispose();
    _comuna.dispose();
    _descripcion.dispose();
    _comentario.dispose();
    super.dispose();
  }

  void _guardar() => Store.I.guardarAlEscribir(i);

  /// Fotos para elegir: primero las tomadas para la venta, luego las del checklist.
  List<(String, String, int?)> get _opciones {
    final delChecklist = <(String, String, int?)>[
      for (final s in checklist)
        for (final it in s.items)
          for (final f in i.results[it.id]?.fotos ?? const <String>[]) (f, it.label, _sevDe(it)),
      for (final (n, d) in i.danos.indexed)
        for (final f in d.fotos) (f, 'Daño ${n + 1}: ${d.nombreZona}', d.sev),
    ];
    final enChecklist = delChecklist.map((e) => e.$1).toSet();
    return [
      for (final f in v.fotos)
        if (!enChecklist.contains(f)) (f, 'Foto de venta', null),
      ...delChecklist,
    ];
  }

  Future<void> _agregarFotos(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final xs = source == ImageSource.camera
          ? [?await picker.pickImage(source: source, maxWidth: 1600, imageQuality: 80)]
          : await picker.pickMultiImage(maxWidth: 1600, imageQuality: 80);
      for (final x in xs) {
        v.fotos.add(await Store.I.addPhoto(x.path, i));
      }
      if (xs.isNotEmpty) {
        await Store.I.save(i);
        setState(() {});
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(source == ImageSource.camera ? 'No se pudo abrir la cámara.' : 'No se pudo abrir la galería.')));
    }
  }

  static const maxVideos = 4;

  void _toggleVideo(Video video) {
    final on = v.videos.contains(video.archivo);
    if (!on && v.videos.length >= maxVideos) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Máximo $maxVideos videos por publicación.')));
      return;
    }
    setState(() => on ? v.videos.remove(video.archivo) : v.videos.add(video.archivo));
    Store.I.save(i);
  }

  Future<void> _grabarVideo() async {
    final antes = i.videos.length;
    await agregarVideo(context, i);
    if (i.videos.length > antes && v.videos.length < maxVideos) {
      v.videos.add(i.videos.last.archivo);
      await Store.I.save(i);
    }
    if (mounted) setState(() {});
  }

  Widget _videos() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Videos', style: display(18))),
          Text('${v.videos.length} elegidos', style: const TextStyle(color: C.muted, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 4),
        const Text('Opcional, hasta $maxVideos. Por ejemplo, el motor en marcha o una vuelta alrededor del auto.',
            style: TextStyle(color: C.muted, fontSize: 13)),
        for (final video in i.videos) ...[
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _toggleVideo(video),
            child: Row(children: [
              VideoThumb(video, width: 84, height: 60),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(video.nota.trim().isEmpty ? 'Sin descripción' : video.nota.trim(),
                      maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (_problemaDe(video) case final sev?) ...[
                    const SizedBox(height: 3),
                    SevPill(sev == 2 ? 'Muestra un problema' : 'Muestra una observación', sev),
                  ] else if (puntoDe(video) case final p?)
                    Text(p, style: const TextStyle(color: C.muted, fontSize: 12.5)),
                ]),
              ),
              Checkbox(value: v.videos.contains(video.archivo), onChanged: (_) => _toggleVideo(video)),
            ]),
          ),
        ],
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _grabarVideo,
          icon: const Icon(Icons.videocam_outlined),
          label: const Text('Agregar video para la venta'),
        ),
      ]);

  /// Gravedad del punto asociado al video, si es una observación o problema.
  int? _problemaDe(Video video) {
    final f = video.item == null ? null : findItem(video.item!);
    final sev = f == null ? null : _sevDe(f.$2);
    return sev != null && sev > 0 ? sev : null;
  }

  void _toggle(String f) {
    setState(() => v.fotos.contains(f) ? v.fotos.remove(f) : v.fotos.add(f));
    Store.I.save(i);
  }

  String? get _falta {
    if (v.publicada != null) return null; // lo de venta ya se edita en Garage
    if ((v.precio ?? 0) <= 0) return 'Falta el precio.';
    if (v.fotos.isEmpty) return 'Elige al menos una foto.';
    if (!v.autorizada) return 'Confirma que el dueño autorizó publicar.';
    return null;
  }

  Future<void> _publicar() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Store.I.guardarPendiente();
    final nueva = v.publicada == null;
    setState(() => _avance = 'Preparando…');
    try {
      await Marketplace.publicar(i, (t) => mounted ? setState(() => _avance = t) : null);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(nueva ? 'Publicado en atlasmotors.cl' : 'Informe actualizado en la web')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is String ? e : 'No se pudo publicar. Revisa tu señal e intenta de nuevo.')));
    } finally {
      if (mounted) setState(() => _avance = null);
    }
  }

  Future<void> _quitar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('¿Quitar de la web?'),
        content: const Text('El auto deja de aparecer en atlasmotors.cl. La inspección no se borra y puedes volver a publicarlo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              style: TextButton.styleFrom(foregroundColor: C.sev[2]),
              child: const Text('Quitar')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _avance = 'Quitando…');
    try {
      await Marketplace.despublicar(i);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('No se pudo quitar. Revisa tu señal e intenta de nuevo.')));
      }
    } finally {
      if (mounted) setState(() => _avance = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final publicada = v.publicada != null;
    final hs = i.hallazgos;
    final falta = _falta;
    return Scaffold(
      appBar: AppBar(title: const Text('Vender este auto')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: _avance != null
              ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5)),
                  const SizedBox(width: 12),
                  Text(_avance!, style: const TextStyle(fontWeight: FontWeight.w600)),
                ])
              : Column(mainAxisSize: MainAxisSize.min, children: [
                  if (falta != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(falta, style: const TextStyle(color: C.muted, fontSize: 13)),
                    ),
                  GoldButton(publicada ? 'Actualizar informe en la web' : 'Publicar en atlasmotors.cl',
                      icon: Icons.storefront_outlined, onPressed: falta == null ? _publicar : null),
                ]),
        ),
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          if (publicada) ...[
            _publicadaCard(),
            const SizedBox(height: 14),
            _garageCard(),
          ] else
            _queSePublica(),
          const SizedBox(height: 22),
          if (!publicada) ..._datosDeVenta(),
          TextField(
            controller: _comentario,
            minLines: 2,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            decoration: const InputDecoration(
                labelText: 'Comentario del inspector',
                helperText: 'Lo leen los compradores. Parte de tu conclusión; ajústalo si hace falta.',
                helperMaxLines: 2),
            onChanged: (t) {
              v.comentario = t;
              _guardar();
            },
          ),
          if (!publicada) ..._fotosYVideos(),
          const SizedBox(height: 22),
          Text('Lo que ven los compradores', style: display(18)),
          const SizedBox(height: 4),
          const Text(
              'Los puntos con observación o problema se muestran siempre, como texto. Es lo que hace creíble el sello de Atlas Motors.',
              style: TextStyle(color: C.muted, fontSize: 13)),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('Puntaje ${i.score ?? '–'}/100', style: const TextStyle(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  if (i.recomendacion != null) SevPill(recomendaciones[i.recomendacion!], i.recomendacion!),
                ]),
                const SizedBox(height: 8),
                if (hs.isEmpty)
                  const Text('Sin observaciones ni problemas.', style: TextStyle(color: C.muted))
                else
                  for (final h in hs)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(children: [
                        SevPill(h.opt.label, h.opt.sev),
                        const SizedBox(width: 8),
                        Expanded(child: Text(h.item.label, style: const TextStyle(fontSize: 14))),
                      ]),
                    ),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          CheckboxListTile(
            value: v.autorizada,
            onChanged: (b) {
              setState(() => v.autorizada = b ?? false);
              Store.I.save(i);
            },
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('El dueño del auto autorizó publicarlo'),
            subtitle: const Text('No se publica la patente ni sus datos. Los interesados escriben al WhatsApp de Atlas.'),
          ),
        ],
      ),
    );
  }

  List<Widget> _datosDeVenta() => [
          Text('Datos de venta', style: display(18)),
          const SizedBox(height: 10),
          TextField(
            controller: _precio,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            decoration: InputDecoration(
              labelText: 'Precio',
              prefixText: '\$ ',
              helperText: v.precio == null ? 'Precio que pide el dueño.' : clp(v.precio!),
            ),
            onChanged: (t) {
              setState(() => v.precio = int.tryParse(t));
              _guardar();
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _comuna,
            textCapitalization: TextCapitalization.words,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            decoration: const InputDecoration(labelText: 'Comuna', hintText: 'Ej. La Serena'),
            onChanged: (t) {
              v.comuna = t;
              _guardar();
            },
          ),
          const SizedBox(height: 14),
          _Opciones('Combustible', combustibles, v.combustible, (o) {
            setState(() => v.combustible = v.combustible == o ? '' : o);
            Store.I.save(i);
          }),
          const SizedBox(height: 12),
          _Opciones('Transmisión', transmisiones, v.transmision, (o) {
            setState(() => v.transmision = v.transmision == o ? '' : o);
            Store.I.save(i);
          }),
          const SizedBox(height: 14),
          TextField(
            controller: _descripcion,
            minLines: 2,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            decoration: const InputDecoration(
                labelText: 'Descripción del vendedor (opcional)',
                hintText: 'Ej. Único dueño, mantenciones en la marca, neumáticos nuevos.'),
            onChanged: (t) {
              v.descripcion = t;
              _guardar();
            },
          ),
          const SizedBox(height: 12),
      ];

  List<Widget> _fotosYVideos() => [
          const SizedBox(height: 22),
          Row(children: [
            Expanded(child: Text('Fotos', style: display(18))),
            Text('${v.fotos.length} elegidas', style: const TextStyle(color: C.muted, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 4),
          const Text('Toca para elegir. La primera es la portada. Suma fotos lindas del auto: exterior, interior y motor.',
              style: TextStyle(color: C.muted, fontSize: 13)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _agregarFotos(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Tomar foto'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _agregarFotos(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Galería'),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          _fotos(),
          const SizedBox(height: 22),
          _videos(),
      ];

  Widget _garageCard() => Card(
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
          leading: const Icon(Icons.garage_outlined, color: C.gold700),
          title: const Text('Precio, fotos y videos', style: TextStyle(fontWeight: FontWeight.w700)),
          subtitle: const Text('Ahora se editan en Garage, también por el equipo de fotografía y venta.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _abrirGarage,
        ),
      );

  Future<void> _abrirGarage() async {
    final DocumentSnapshot<Map<String, dynamic>> d;
    try {
      d = await FirebaseFirestore.instance.collection('publicaciones').doc(i.id).get();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Sin conexión. Revisa tu señal e intenta de nuevo.')));
      }
      return;
    }
    if (!mounted) return;
    if (!d.exists) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Este auto ya no está publicado.')));
      return;
    }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => GarageAutoScreen(aviso: Aviso(d.id, d.data()!))));
  }

  Widget _queSePublica() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: C.green900, borderRadius: BorderRadius.circular(16)),
        child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.storefront_outlined, color: C.gold300),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'El auto aparece en atlasmotors.cl con sus fotos, el puntaje de la inspección y una ficha PDF para descargar. '
              'Los interesados te escriben por WhatsApp.',
              style: TextStyle(color: C.gold200, fontSize: 13.5, height: 1.35),
            ),
          ),
        ]),
      );

  Widget _publicadaCard() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: C.sevBg[0],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.sev[0], width: 1.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.check_circle, color: C.sev[0]),
            const SizedBox(width: 8),
            Text('Publicado en atlasmotors.cl', style: TextStyle(fontWeight: FontWeight.w700, color: C.sev[0], fontSize: 15.5)),
          ]),
          const SizedBox(height: 6),
          const Text('Si cambias algo de la inspección o agregas un trabajo posterior, toca "Actualizar informe en la web".',
              style: TextStyle(color: C.muted, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            Builder(
              builder: (bc) => TextButton.icon(
                onPressed: () => compartir(bc, '${i.vehiculo} en venta, inspeccionado por Atlas Motors: ${Marketplace.enlace(i)}'),
                icon: const Icon(Icons.ios_share, size: 19),
                label: const Text('Compartir enlace'),
              ),
            ),
            TextButton.icon(
              onPressed: _avance == null ? _quitar : null,
              style: TextButton.styleFrom(foregroundColor: C.sev[2]),
              icon: const Icon(Icons.remove_circle_outline, size: 19),
              label: const Text('Quitar de la web'),
            ),
          ]),
        ]),
      );

  Widget _fotos() {
    final ops = _opciones;
    if (ops.isEmpty) {
      return const Text('Esta inspección no tiene fotos todavía.', style: TextStyle(color: C.muted));
    }
    return LayoutBuilder(builder: (context, box) {
      final w = (box.maxWidth - 16) / 3;
      return Wrap(spacing: 8, runSpacing: 8, children: [
        for (final (f, label, sev) in ops)
          _Foto(
            nombre: f,
            label: label,
            sev: sev,
            width: w,
            orden: v.fotos.indexOf(f),
            onTap: () => _toggle(f),
            onBorrar: label == 'Foto de venta' ? () async {
              await Store.I.quitarFotoVenta(i, f);
              setState(() {});
            } : null,
          ),
      ]);
    });
  }
}

class _Foto extends StatelessWidget {
  final String nombre, label;
  final int? sev;
  final double width;
  final int orden; // -1 si no está elegida
  final VoidCallback onTap;
  final VoidCallback? onBorrar;
  const _Foto(
      {required this.nombre, required this.label, required this.sev, required this.width, required this.orden, required this.onTap, this.onBorrar});

  @override
  Widget build(BuildContext context) {
    final on = orden >= 0;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onBorrar,
      child: SizedBox(
        width: width,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(Store.I.photoFile(nombre),
                  width: width,
                  height: width * .75,
                  fit: BoxFit.cover,
                  cacheWidth: 300,
                  errorBuilder: (_, _, _) => Container(
                      width: width, height: width * .75, color: C.cream2, child: const Icon(Icons.cloud_off_outlined, color: C.muted))),
            ),
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: on ? C.gold : Colors.transparent, width: 3),
                  color: on ? null : Colors.white.withValues(alpha: .35),
                ),
              ),
            ),
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? C.gold : Colors.black45,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: on
                    ? Text(orden == 0 ? '★' : '${orden + 1}',
                        style: const TextStyle(color: C.ink, fontWeight: FontWeight.w800, fontSize: 12))
                    : null,
              ),
            ),
            if (sev != null && sev! > 0)
              Positioned(
                left: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: C.sev[sev!], borderRadius: BorderRadius.circular(6)),
                  child: Text(sev == 2 ? 'Problema' : 'Obs.',
                      style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700)),
                ),
              ),
          ]),
          const SizedBox(height: 3),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: C.muted)),
        ]),
      ),
    );
  }
}

/// Opciones en botones del mismo ancho (tocar de nuevo desmarca).
class _Opciones extends StatelessWidget {
  final String titulo;
  final List<String> opciones;
  final String valor;
  final ValueChanged<String> onTap;
  const _Opciones(this.titulo, this.opciones, this.valor, this.onTap);

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo, style: const TextStyle(color: C.muted, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(children: [
          for (final (n, o) in opciones.indexed) ...[
            if (n > 0) const SizedBox(width: 6),
            Expanded(
              child: Material(
                color: valor == o ? C.green900 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onTap(o),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: valor == o ? C.green900 : C.line, width: 1.5),
                    ),
                    child: Text(o,
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13.5, color: valor == o ? C.gold300 : C.text)),
                  ),
                ),
              ),
            ),
          ],
        ]),
      ]);
}
