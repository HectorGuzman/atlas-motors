import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../checklist.dart';
import '../store.dart';
import '../theme.dart';

/// Graba (o elige de la galería) un video de hasta 30 segundos y lo agrega a la
/// inspección. Si viene [item], queda asociado a ese punto del checklist.
/// Después abre el video para escribir qué muestra.
Future<void> agregarVideo(BuildContext context, Inspection i, {String? item}) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (c) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.videocam_outlined),
            title: const Text('Grabar video'),
            subtitle: const Text('Hasta $maxSegundosVideo segundos, con sonido'),
            onTap: () => Navigator.pop(c, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.video_library_outlined),
            title: const Text('Elegir de la galería'),
            subtitle: const Text('Por ejemplo, un trozo del video de los lentes'),
            onTap: () => Navigator.pop(c, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (source == null || !context.mounted) return;
  XFile? x;
  try {
    x = await ImagePicker().pickVideo(
      source: source,
      maxDuration: const Duration(seconds: maxSegundosVideo),
    );
  } catch (_) {
    if (context.mounted) {
      _aviso(
        context,
        source == ImageSource.camera
            ? 'No se pudo abrir la cámara (el simulador no tiene). Usa la galería.'
            : 'No se pudo abrir la galería.',
      );
    }
    return;
  }
  if (x == null || !context.mounted) return;

  // Comprimir toma unos segundos: se avisa para que no parezca pegado.
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
            SizedBox(width: 16),
            Expanded(child: Text('Preparando el video…')),
          ],
        ),
      ),
    ),
  );
  Video? v;
  String? error;
  try {
    v = await Store.I.addVideo(x.path, i, item: item);
  } catch (e) {
    error = e is String ? e : 'No se pudo agregar el video.';
  }
  if (!context.mounted) return;
  Navigator.pop(context); // cierra "Preparando…"
  if (error != null) return _aviso(context, error);
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => VideoScreen(inspection: i, video: v!, nuevo: true),
    ),
  );
}

void _aviso(BuildContext context, String texto) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

String duracion(int seg) => '0:${seg.toString().padLeft(2, '0')}';

/// Miniatura de un video con el botón de play y la duración.
class VideoThumb extends StatelessWidget {
  final Video video;
  final double width, height;
  final VoidCallback? onTap;
  const VideoThumb(this.video, {super.key, this.width = 96, this.height = 72, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.file(
            Store.I.photoFile(video.miniatura),
            width: width,
            height: height,
            fit: BoxFit.cover,
            cacheWidth: (width * 3).round(),
            errorBuilder: (_, _, _) => Container(width: width, height: height, color: C.green800),
          ),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
          ),
          Positioned(
            right: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(5)),
              child: Text(
                duracion(video.segundos),
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Apartado "Videos" en el resumen de la inspección.
class VideosCard extends StatelessWidget {
  final Inspection i;
  const VideosCard(this.i, {super.key});

  @override
  Widget build(BuildContext context) {
    final vs = i.videos;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Videos', style: display(18)),
                const Spacer(),
                if (vs.isNotEmpty)
                  Text(
                    '${vs.length}',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: C.muted),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Ruidos, fugas o cómo funciona algo. Hasta $maxSegundosVideo segundos, con sonido.',
              style: TextStyle(color: C.muted, fontSize: 13),
            ),
            for (final v in vs) ...[
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VideoScreen(inspection: i, video: v),
                  ),
                ),
                child: Row(
                  children: [
                    VideoThumb(v, width: 84, height: 60),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            v.nota.trim().isEmpty ? 'Sin descripción' : v.nota.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: v.nota.trim().isEmpty ? C.muted : C.text,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            puntoDe(v) ?? 'Sin punto asociado',
                            style: const TextStyle(color: C.muted, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: C.muted),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => agregarVideo(context, i),
              icon: const Icon(Icons.videocam_outlined),
              label: const Text('Agregar video'),
              style: OutlinedButton.styleFrom(
                foregroundColor: C.green900,
                side: const BorderSide(color: C.green700, width: 1.5),
                minimumSize: const Size.fromHeight(46),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Motor · Ruidos del motor", o null si el video no está asociado a un punto.
String? puntoDe(Video v) {
  if (v.item == null) return null;
  final f = findItem(v.item!);
  return f == null ? null : '${f.$1.title} · ${f.$2.label}';
}

/// Ver un video, describir qué muestra, asociarlo a un punto, enviarlo o borrarlo.
class VideoScreen extends StatefulWidget {
  final Inspection inspection;
  final Video video;
  final bool nuevo;
  const VideoScreen({super.key, required this.inspection, required this.video, this.nuevo = false});
  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  Inspection get i => widget.inspection;
  Video get v => widget.video;
  late final _nota = TextEditingController(text: v.nota);
  VideoPlayerController? _player;
  File? _file;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final f = await Store.I.archivoVideo(i, v);
      final p = VideoPlayerController.file(f);
      await p.initialize();
      if (!mounted) return p.dispose();
      p.addListener(() => setState(() {}));
      setState(() {
        _file = f;
        _player = p;
      });
      if (widget.nuevo) p.play();
    } catch (e) {
      if (mounted) setState(() => _error = e is String ? e : 'No se pudo abrir el video.');
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    _nota.dispose();
    Store.I.guardarPendiente();
    super.dispose();
  }

  Future<void> _elegirPunto() async {
    final elegido = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (c) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .7,
        maxChildSize: .92,
        builder: (_, scroll) => ListView(
          controller: scroll,
          children: [
            ListTile(
              leading: const Icon(Icons.block_outlined),
              title: const Text('Sin punto asociado'),
              onTap: () => Navigator.pop(c, ''),
            ),
            for (final s in checklist) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Text(
                  s.title,
                  style: const TextStyle(fontWeight: FontWeight.w800, color: C.green700),
                ),
              ),
              for (final it in s.items)
                ListTile(
                  dense: true,
                  title: Text(it.label, style: const TextStyle(fontSize: 15)),
                  trailing: v.item == it.id ? const Icon(Icons.check, color: C.ok) : null,
                  onTap: () => Navigator.pop(c, it.id),
                ),
            ],
          ],
        ),
      ),
    );
    if (elegido == null) return;
    setState(() => v.item = elegido.isEmpty ? null : elegido);
    Store.I.save(i);
  }

  Future<void> _borrar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('¿Borrar este video?'),
        content: const Text('Se quita de la inspección y del informe.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: C.sev[2]),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await Store.I.removeVideo(i, v);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _enviar(BuildContext bc) async {
    final f = _file;
    if (f == null) return;
    final box = bc.findRenderObject() as RenderBox?;
    final texto = [
      '*Atlas Motors · ${i.vehiculo}*',
      ?puntoDe(v),
      if (v.nota.trim().isNotEmpty) v.nota.trim(),
    ].join('\n');
    await SharePlus.instance.share(
      ShareParams(
        text: texto,
        files: [XFile(f.path, mimeType: 'video/mp4')],
        sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _player;
    final punto = puntoDe(v);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video'),
        actions: [IconButton(onPressed: _borrar, icon: const Icon(Icons.delete_outline), tooltip: 'Borrar video')],
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: Colors.black,
              alignment: Alignment.center,
              // Un video vertical no debe tapar la descripción: alto máximo ~45 % de la pantalla.
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .45),
                child: AspectRatio(
                  aspectRatio: p?.value.isInitialized == true ? p!.value.aspectRatio : 16 / 9,
                  child: p == null
                      ? Center(
                          child: _error == null
                              ? const CircularProgressIndicator(color: C.gold)
                              : Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                        )
                      : GestureDetector(
                          onTap: () => p.value.isPlaying ? p.pause() : p.play(),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              VideoPlayer(p),
                              if (!p.value.isPlaying)
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
                                ),
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: VideoProgressIndicator(
                                  p,
                                  allowScrubbing: true,
                                  colors: const VideoProgressColors(playedColor: C.gold, bufferedColor: Colors.white24),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nota,
            autofocus: widget.nuevo,
            minLines: 2,
            maxLines: 5,
            maxLength: 300,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: '¿Qué muestra el video?',
              hintText: 'Ej: ruido metálico al girar a la izquierda',
            ),
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            onChanged: (t) {
              v.nota = t;
              Store.I.guardarAlEscribir(i);
            },
          ),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: const Icon(Icons.checklist_rounded, color: C.green700),
              title: Text(
                punto ?? 'Asociar a un punto del checklist',
                style: TextStyle(fontWeight: FontWeight.w600, color: punto == null ? C.green700 : C.text),
              ),
              subtitle: Text(punto == null ? 'Opcional' : 'Toca para cambiarlo'),
              trailing: const Icon(Icons.chevron_right, color: C.muted),
              onTap: _elegirPunto,
            ),
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (bc) => OutlinedButton.icon(
              onPressed: _file == null ? null : () => _enviar(bc),
              icon: const Icon(Icons.send_outlined),
              label: const Text('Enviar al cliente'),
              style: OutlinedButton.styleFrom(
                foregroundColor: C.green900,
                side: const BorderSide(color: C.green700, width: 1.5),
                minimumSize: const Size.fromHeight(46),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          if (v.url == null && !i.esEjemplo) ...[
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(Icons.cloud_upload_outlined, size: 18, color: C.muted),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Se sube a la nube cuando haya señal. Después aparece en el informe con un código QR.',
                    style: TextStyle(color: C.muted, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
