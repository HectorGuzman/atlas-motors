import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../marketplace.dart';
import '../messages.dart';
import '../store.dart';
import '../theme.dart';
import 'home.dart' show confirmarSalida;

/// Un auto publicado en atlasmotors.cl, como lo ve Garage.
class Aviso {
  final String id;
  final Map<String, dynamic> d;
  Aviso(this.id, this.d);

  String get titulo => [d['marca'], d['modelo'], d['anio']].where((x) => x != null && '$x'.isNotEmpty).join(' ');
  int? get precio => d['precio'] as int?;
  int? get puntaje => d['puntaje'] as int?;
  int? get km => d['km'] as int?;
  List<String> get fotos => [for (final f in (d['fotos'] as List? ?? [])) '$f'];
  List<Map<String, dynamic>> get videos => [for (final v in (d['videos'] as List? ?? [])) Map<String, dynamic>.from(v)];
  String texto(String k) => d[k] is String ? d[k] : '';
}

/// Garage: los autos en venta. Lo usan los admin y el equipo Garage
/// (fotografía, video y venta), que no ven las inspecciones.
class GarageScreen extends StatelessWidget {
  const GarageScreen({super.key});

  static Stream<List<Aviso>> _avisos() => FirebaseFirestore.instance
      .collection('publicaciones')
      .orderBy('publicado', descending: true)
      .snapshots()
      .map((s) => [for (final d in s.docs) Aviso(d.id, d.data())]);

  @override
  Widget build(BuildContext context) {
    final raiz = !Navigator.canPop(context);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: raiz ? 12 : null,
        title: raiz ? Image.asset('assets/logo-wordmark.jpg', height: 44) : const Text('Garage'),
        centerTitle: false,
        actions: [
          if (raiz) IconButton(tooltip: 'Cerrar sesión', icon: const Icon(Icons.logout), onPressed: () => confirmarSalida(context)),
        ],
      ),
      body: StreamBuilder<List<Aviso>>(
        stream: _avisos(),
        builder: (context, snap) {
          final avisos = snap.data;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            children: [
              if (raiz) ...[Text('Hola, ${Store.I.userName}', style: display(24)), const SizedBox(height: 4)],
              Text(raiz ? 'Garage · autos en venta' : 'Autos en venta', style: raiz ? const TextStyle(color: C.muted) : display(22)),
              const SizedBox(height: 4),
              const Text('Cambia precio, fotos y videos. Se ve al instante en atlasmotors.cl.',
                  style: TextStyle(color: C.muted, fontSize: 13)),
              const SizedBox(height: 16),
              if (snap.hasError)
                const _Vacio(Icons.cloud_off_outlined, 'No se pudieron cargar los autos', 'Revisa tu señal e intenta de nuevo.')
              else if (avisos == null)
                const Padding(padding: EdgeInsets.only(top: 60), child: Center(child: CircularProgressIndicator()))
              else if (avisos.isEmpty)
                const _Vacio(Icons.garage_outlined, 'No hay autos en venta', 'Se publican desde una inspección, con "Vender este auto".')
              else
                for (final a in avisos) ...[
                  _AvisoCard(a, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GarageAutoScreen(aviso: a)))),
                  const SizedBox(height: 12),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  final IconData icon;
  final String titulo, detalle;
  const _Vacio(this.icon, this.titulo, this.detalle);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(children: [
          Icon(icon, size: 56, color: C.gold700),
          const SizedBox(height: 12),
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          Text(detalle, textAlign: TextAlign.center, style: const TextStyle(color: C.muted)),
        ]),
      );
}

class _AvisoCard extends StatelessWidget {
  final Aviso a;
  final VoidCallback onTap;
  const _AvisoCard(this.a, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fotos = a.fotos;
    final videos = a.videos.length;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(children: [
          SizedBox(
            width: 112,
            height: 96,
            child: fotos.isEmpty
                ? Container(color: C.green900, child: const Icon(Icons.directions_car_outlined, color: C.gold300))
                : Image.network(fotos.first, fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(color: C.green900)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.titulo, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: C.green950)),
                const SizedBox(height: 2),
                Text(a.precio == null ? 'Sin precio' : clp(a.precio!),
                    style: TextStyle(fontWeight: FontWeight.w700, color: a.precio == null ? C.muted : C.gold700)),
                const SizedBox(height: 4),
                Text(
                  [
                    fotos.length == 1 ? '1 foto' : '${fotos.length} fotos',
                    if (videos > 0) videos == 1 ? '1 video' : '$videos videos',
                    if (a.puntaje != null) 'puntaje ${a.puntaje}',
                  ].join(' · '),
                  style: const TextStyle(color: C.muted, fontSize: 12.5),
                ),
              ]),
            ),
          ),
          const Padding(padding: EdgeInsets.only(right: 10), child: Icon(Icons.chevron_right, color: C.muted)),
        ]),
      ),
    );
  }
}

/// Editar un auto en venta: datos de venta, fotos y videos. Lo que sale de la
/// inspección (puntaje, hallazgos, ficha) no se edita acá.
class GarageAutoScreen extends StatefulWidget {
  final Aviso aviso;
  const GarageAutoScreen({super.key, required this.aviso});
  @override
  State<GarageAutoScreen> createState() => _GarageAutoScreenState();
}

class _GarageAutoScreenState extends State<GarageAutoScreen> {
  static const maxFotos = 40;
  static const maxVideos = 4;
  static const maxSegundos = 60;
  static const _nativo = MethodChannel('atlas/video');

  Aviso get a => widget.aviso;
  late final _precio = TextEditingController(text: a.precio?.toString() ?? '');
  late final _comuna = TextEditingController(text: a.texto('comuna'));
  late final _descripcion = TextEditingController(text: a.texto('descripcion'));
  late String _combustible = a.texto('combustible');
  late String _transmision = a.texto('transmision');
  late final List<String> _fotos = a.fotos;
  late final List<Map<String, dynamic>> _videos = a.videos;

  /// Subidos en esta edición: si no se guarda, se borran.
  final _nuevos = <String>{};

  /// Quitados en esta edición: se borran de la nube al guardar.
  final _quitados = <String>{};
  bool _cambios = false;
  String? _avance;

  @override
  void dispose() {
    _precio.dispose();
    _comuna.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  void _cambio() => setState(() => _cambios = true);

  void _aviso(String t) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  String _nombre(String ext) => 'g-${DateTime.now().microsecondsSinceEpoch}.$ext';

  Future<void> _agregarFotos(ImageSource source) async {
    if (_fotos.length >= maxFotos) return _aviso('Máximo $maxFotos fotos por auto.');
    final List<XFile> xs;
    try {
      final picker = ImagePicker();
      xs = source == ImageSource.camera
          ? [?await picker.pickImage(source: source)]
          : await picker.pickMultiImage(limit: maxFotos - _fotos.length);
    } catch (_) {
      return _aviso(source == ImageSource.camera ? 'No se pudo abrir la cámara.' : 'No se pudo abrir la galería.');
    }
    if (xs.isEmpty) return;
    try {
      for (final (n, x) in xs.take(maxFotos - _fotos.length).indexed) {
        setState(() => _avance = xs.length == 1 ? 'Subiendo la foto…' : 'Subiendo foto ${n + 1} de ${xs.length}…');
        final url = await Marketplace.subirFoto(a.id, File(x.path), _nombre('jpg'));
        _nuevos.add(url);
        _fotos.add(url);
        _cambios = true;
      }
    } catch (e) {
      debugPrint('Foto de Garage: $e');
      _aviso(e is String ? e : 'No se pudo subir una foto. Revisa tu señal e intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _avance = null);
    }
  }

  Future<void> _opcionesFoto(int n) async {
    final r = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (n > 0)
            ListTile(leading: const Icon(Icons.star_outline), title: const Text('Usar como portada'), onTap: () => Navigator.pop(c, 'portada')),
          if (n > 0)
            ListTile(leading: const Icon(Icons.arrow_back), title: const Text('Mover antes'), onTap: () => Navigator.pop(c, 'antes')),
          if (n < _fotos.length - 1)
            ListTile(leading: const Icon(Icons.arrow_forward), title: const Text('Mover después'), onTap: () => Navigator.pop(c, 'despues')),
          ListTile(
            leading: Icon(Icons.delete_outline, color: C.sev[2]),
            title: Text('Quitar foto', style: TextStyle(color: C.sev[2])),
            onTap: () => Navigator.pop(c, 'quitar'),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (r == null) return;
    setState(() {
      final f = _fotos[n];
      switch (r) {
        case 'portada':
          _fotos..removeAt(n)..insert(0, f);
        case 'antes':
          _fotos..removeAt(n)..insert(n - 1, f);
        case 'despues':
          _fotos..removeAt(n)..insert(n + 1, f);
        case 'quitar':
          _fotos.removeAt(n);
          _quitados.add(f);
      }
      _cambios = true;
    });
  }

  Future<void> _agregarVideo() async {
    if (_videos.length >= maxVideos) return _aviso('Máximo $maxVideos videos por auto.');
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.videocam_outlined),
            title: const Text('Grabar video'),
            subtitle: const Text('Hasta $maxSegundos segundos, con sonido'),
            onTap: () => Navigator.pop(c, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.video_library_outlined),
            title: const Text('Elegir de la galería'),
            subtitle: const Text('Ya editado, de hasta $maxSegundos segundos'),
            onTap: () => Navigator.pop(c, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (source == null || !mounted) return;
    final XFile? x;
    try {
      x = await ImagePicker().pickVideo(source: source, maxDuration: const Duration(seconds: maxSegundos));
    } catch (_) {
      return _aviso(source == ImageSource.camera ? 'No se pudo abrir la cámara.' : 'No se pudo abrir la galería.');
    }
    if (x == null || !mounted) return;
    double dur;
    try {
      dur = (await _nativo.invokeMethod<double>('duracion', {'path': x.path}))!;
    } catch (_) {
      return _aviso('No se pudo leer el video. Prueba con otro.');
    }
    if (dur > maxSegundos + 1) {
      return _aviso('El video dura ${dur.round()} segundos. El máximo es $maxSegundos: recórtalo en Fotos.');
    }
    if (!mounted) return;
    final nota = await _pedirNota();
    if (nota == null) return;
    try {
      final v = await Marketplace.subirVideo(a.id, x.path, _nombre('mp4'),
          nota: nota, segundos: dur.round(), avance: (t) => setState(() => _avance = t));
      _nuevos.addAll([v['url'] as String, if (v['poster'] != null) v['poster'] as String]);
      _videos.add(v);
      _cambios = true;
    } catch (e) {
      debugPrint('Video de Garage: $e');
      _aviso(e is String ? e : 'No se pudo subir el video. Revisa tu señal e intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _avance = null);
    }
  }

  Future<String?> _pedirNota([String actual = '']) {
    final c = TextEditingController(text: actual);
    return showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('¿Qué muestra el video?'),
        content: TextField(
          controller: c,
          autofocus: true,
          maxLength: 120,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Ej. Vuelta alrededor del auto'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(d, c.text.trim()), child: const Text('Listo')),
        ],
      ),
    ).whenComplete(c.dispose);
  }

  void _quitarVideo(int n) {
    final v = _videos.removeAt(n);
    _quitados.addAll([v['url'] as String, if (v['poster'] != null) v['poster'] as String]);
    _cambio();
  }

  /// Borra archivos de la carpeta pública (los quitados al guardar, o los
  /// subidos si se descartan los cambios). Si falla, quedan huérfanos: no es grave.
  Future<void> _borrar(Iterable<String> urls) async {
    for (final u in urls) {
      try {
        await FirebaseStorage.instanceFor(bucket: 'gs://atlas-motors-cl-fotos').refFromURL(u).delete();
      } catch (e) {
        debugPrint('No se pudo borrar $u: $e');
      }
    }
  }

  Future<void> _guardar() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final precio = int.tryParse(_precio.text);
    if (_precio.text.isNotEmpty && (precio == null || precio <= 0)) return _aviso('Revisa el precio.');
    if (_fotos.isEmpty) return _aviso('El auto necesita al menos una foto.');
    setState(() => _avance = 'Guardando…');
    try {
      await FirebaseFirestore.instance.collection('publicaciones').doc(a.id).update({
        'precio': precio,
        'comuna': _comuna.text.trim(),
        'combustible': _combustible,
        'transmision': _transmision,
        'descripcion': _descripcion.text.trim(),
        'fotos': _fotos,
        'videos': _videos,
        'actualizado': FieldValue.serverTimestamp(),
      });
      await _borrar(_quitados.where((u) => !_fotos.contains(u)));
      _nuevos.clear();
      _cambios = false;
      if (!mounted) return;
      Navigator.pop(context);
      _aviso('Listo, los cambios ya se ven en atlasmotors.cl.');
    } catch (e) {
      debugPrint('Guardar en Garage: $e');
      _aviso(e is FirebaseException && e.code == 'not-found'
          ? 'Este auto ya no está publicado.'
          : 'No se pudo guardar. Revisa tu señal e intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _avance = null);
    }
  }

  Future<void> _salir() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('¿Descartar los cambios?'),
        content: const Text('Lo que cambiaste en este auto no se guardará.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Seguir editando')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              style: TextButton.styleFrom(foregroundColor: C.sev[2]),
              child: const Text('Descartar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    unawaited(_borrar(_nuevos.toList()));
    _cambios = false;
    Navigator.pop(context);
  }

  Widget _chips(String titulo, List<String> opciones, String actual, ValueChanged<String> elegir) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600, color: C.muted)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final o in opciones)
            ChoiceChip(
              label: Text(o),
              selected: actual == o,
              onSelected: _avance != null ? null : (_) => elegir(actual == o ? '' : o),
            ),
        ]),
      ]);

  @override
  Widget build(BuildContext context) {
    final ocupado = _avance != null;
    return PopScope(
      canPop: !_cambios && !ocupado,
      onPopInvokedWithResult: (popped, _) {
        if (!popped && !ocupado) _salir();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(a.titulo, overflow: TextOverflow.ellipsis)),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: ocupado
                ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5)),
                    const SizedBox(width: 12),
                    Flexible(child: Text(_avance!, style: const TextStyle(fontWeight: FontWeight.w600))),
                  ])
                : GoldButton(_cambios ? 'Guardar cambios' : 'Sin cambios',
                    icon: Icons.check, onPressed: _cambios ? _guardar : null),
          ),
        ),
        body: AbsorbPointer(
          absorbing: ocupado,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Row(children: [
                Expanded(
                  child: Text(
                    [
                      if (a.km != null) '${NumberFormat.decimalPattern('es').format(a.km)} km',
                      if (a.puntaje != null) 'Puntaje de inspección ${a.puntaje}/100',
                    ].join(' · '),
                    style: const TextStyle(color: C.muted, fontSize: 13),
                  ),
                ),
                Builder(
                  builder: (bc) => TextButton.icon(
                    onPressed: () => compartir(bc, '${a.titulo} en venta, inspeccionado por Atlas Motors: ${Marketplace.web}/#/auto/${a.id}'),
                    icon: const Icon(Icons.ios_share, size: 19),
                    label: const Text('Compartir'),
                  ),
                ),
              ]),
              if (!Store.I.esAdmin)
                const Padding(
                  padding: EdgeInsets.only(top: 2, bottom: 6),
                  child: Text('El puntaje y los hallazgos vienen de la inspección y no se cambian acá.',
                      style: TextStyle(color: C.muted, fontSize: 12.5)),
                ),
              const SizedBox(height: 14),
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
                  helperText: int.tryParse(_precio.text) == null ? 'Precio que pide el dueño.' : clp(int.parse(_precio.text)),
                ),
                onChanged: (_) => _cambio(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _comuna,
                textCapitalization: TextCapitalization.words,
                onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                decoration: const InputDecoration(labelText: 'Comuna', hintText: 'Ej. La Serena'),
                onChanged: (_) => _cambio(),
              ),
              const SizedBox(height: 14),
              _chips('Combustible', combustibles, _combustible, (o) => setState(() {
                    _combustible = o;
                    _cambios = true;
                  })),
              const SizedBox(height: 12),
              _chips('Transmisión', transmisiones, _transmision, (o) => setState(() {
                    _transmision = o;
                    _cambios = true;
                  })),
              const SizedBox(height: 14),
              TextField(
                controller: _descripcion,
                minLines: 2,
                maxLines: 8,
                maxLength: 3000,
                textCapitalization: TextCapitalization.sentences,
                onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                decoration: const InputDecoration(
                    labelText: 'Descripción del vendedor',
                    hintText: 'Ej. Único dueño, mantenciones en la marca, neumáticos nuevos.'),
                onChanged: (_) => _cambio(),
              ),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: Text('Fotos', style: display(18))),
                Text('${_fotos.length} de $maxFotos', style: const TextStyle(color: C.muted, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 4),
              const Text('La primera es la portada. Toca una foto para moverla o quitarla.',
                  style: TextStyle(color: C.muted, fontSize: 13)),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                children: [
                  for (final (n, f) in _fotos.indexed)
                    GestureDetector(
                      onTap: () => _opcionesFoto(n),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(fit: StackFit.expand, children: [
                          Image.network(f, fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(color: C.cream2)),
                          if (n == 0)
                            Positioned(
                              left: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(color: C.gold, borderRadius: BorderRadius.circular(6)),
                                child: const Text('Portada', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: C.ink)),
                              ),
                            ),
                        ]),
                      ),
                    ),
                ],
              ),
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
              const SizedBox(height: 22),
              Row(children: [
                Expanded(child: Text('Videos', style: display(18))),
                Text('${_videos.length} de $maxVideos', style: const TextStyle(color: C.muted, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 4),
              const Text('Hasta $maxSegundos segundos cada uno. Se les pone la marca de agua y se les quita la ubicación.',
                  style: TextStyle(color: C.muted, fontSize: 13)),
              for (final (n, v) in _videos.indexed) ...[
                const SizedBox(height: 10),
                Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 84,
                      height: 60,
                      child: Stack(fit: StackFit.expand, children: [
                        if (v['poster'] is String)
                          Image.network(v['poster'], fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(color: C.green900))
                        else
                          Container(color: C.green900),
                        const Icon(Icons.play_circle_fill, color: Colors.white70),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final nota = await _pedirNota('${v['nota'] ?? ''}');
                        if (nota != null) {
                          v['nota'] = nota;
                          _cambio();
                        }
                      },
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${v['nota'] ?? ''}'.isEmpty ? 'Sin descripción' : '${v['nota']}',
                            maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('${v['segundos'] ?? 0} s · toca para cambiar el texto',
                            style: const TextStyle(color: C.muted, fontSize: 12)),
                      ]),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Quitar video',
                    icon: Icon(Icons.delete_outline, color: C.sev[2]),
                    onPressed: () => _quitarVideo(n),
                  ),
                ]),
              ],
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _videos.length >= maxVideos ? null : _agregarVideo,
                icon: const Icon(Icons.videocam_outlined),
                label: const Text('Agregar video'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
