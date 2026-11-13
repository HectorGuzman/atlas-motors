import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../checklist.dart';
import '../messages.dart';
import '../store.dart';
import '../theme.dart';

/// Puntos de una sección: estado con un toque, comentario, costo estimado y fotos.
class SectionScreen extends StatefulWidget {
  final Inspection inspection;
  final Section section;
  const SectionScreen({super.key, required this.inspection, required this.section});
  @override
  State<SectionScreen> createState() => _SectionScreenState();
}

class _SectionScreenState extends State<SectionScreen> {
  Inspection get i => widget.inspection;

  @override
  Widget build(BuildContext context) {
    final s = widget.section;
    final idx = checklist.indexOf(s);
    final next = idx < checklist.length - 1 ? checklist[idx + 1] : null;
    return Scaffold(
      appBar: AppBar(
        title: Text('${idx + 1}. ${s.title}'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('${i.answeredIn(s)}/${s.items.length}',
                  style: const TextStyle(color: C.gold300, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        children: [
          Text(s.resumen, style: const TextStyle(color: C.muted, fontSize: 14)),
          if (i.modalidad == 1) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: C.green900, borderRadius: BorderRadius.circular(12)),
              child: const Row(children: [
                Icon(Icons.videocam_outlined, color: C.gold300, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Inspección remota: usa "Enviar al cliente" en cada hallazgo para mandarlo con su foto.',
                      style: TextStyle(color: C.gold200, fontSize: 13)),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 14),
          for (final it in s.items) ...[
            _ItemCard(inspection: i, section: s, item: it, result: i.result(it.id), onChanged: () => setState(() {})),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          if (next != null)
            GoldButton('Siguiente: ${next.title}',
                icon: Icons.arrow_forward,
                onPressed: () => Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (_) => SectionScreen(inspection: i, section: next))))
          else
            GoldButton('Terminar checklist', icon: Icons.check, onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}

class _ItemCard extends StatefulWidget {
  final Inspection inspection;
  final Section section;
  final Item item;
  final ItemResult result;
  final VoidCallback onChanged;
  const _ItemCard(
      {required this.inspection, required this.section, required this.item, required this.result, required this.onChanged});
  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  late final _nota = TextEditingController(text: widget.result.nota);
  late final _costo = TextEditingController(text: widget.result.costo?.toString() ?? '');
  late bool _showNota = widget.result.nota.isNotEmpty;
  ItemResult get r => widget.result;
  Item get it => widget.item;

  /// Gravedad de la opción elegida (null si no hay).
  int? get _sev => r.opt != null && r.opt! < it.opts.length ? it.opts[r.opt!].sev : null;

  @override
  void dispose() {
    _nota.dispose();
    _costo.dispose();
    super.dispose();
  }

  void _changed() {
    Store.I.save();
    widget.onChanged();
  }

  Future<void> _addPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(c, ImageSource.camera)),
          ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              subtitle: const Text('Por ejemplo, una captura del video de los lentes'),
              onTap: () => Navigator.pop(c, ImageSource.gallery)),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (source == null) return;
    try {
      final x = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 75);
      if (x == null) return;
      r.fotos.add(await Store.I.addPhoto(x.path));
      _changed();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(source == ImageSource.camera
              ? 'No se pudo abrir la cámara (el simulador no tiene). Usa la galería.'
              : 'No se pudo abrir la galería.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sev = _sev;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(it.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: C.green950)),
          if (it.ayuda != null) ...[
            const SizedBox(height: 2),
            Text(it.ayuda!, style: const TextStyle(color: C.muted, fontSize: 12.5)),
          ],
          const SizedBox(height: 10),
          Row(children: [
            for (var o = 0; o < it.opts.length; o++) ...[
              if (o > 0) const SizedBox(width: 6),
              Expanded(child: _optButton(it.opts[o], o)),
            ],
          ]),
          if (_showNota) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _nota,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Comentario breve', isDense: true),
              onChanged: (v) {
                r.nota = v;
                Store.I.save();
              },
            ),
          ],
          if (sev != null && sev > 0) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _costo,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
              decoration: const InputDecoration(
                isDense: true,
                labelText: 'Costo estimado de reparación (opcional)',
                prefixText: '\$ ',
                helperText: 'Referencial. Le sirve al cliente para negociar.',
              ),
              onChanged: (v) {
                r.costo = int.tryParse(v);
                _changed();
              },
            ),
          ],
          if (r.fotos.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: r.fotos.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, k) => Stack(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(Store.I.photoFile(r.fotos[k]), width: 96, height: 72, fit: BoxFit.cover),
                  ),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: GestureDetector(
                      onTap: () async {
                        await Store.I.removePhoto(r, r.fotos[k]);
                        widget.onChanged();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 15, color: Colors.white),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Wrap(spacing: 0, children: [
            _action(Icons.edit_note, _showNota ? 'Ocultar' : 'Comentario', () => setState(() => _showNota = !_showNota)),
            _action(Icons.add_a_photo_outlined, 'Foto', _addPhoto),
            if (sev != null && (sev > 0 || r.fotos.isNotEmpty))
              Builder(
                builder: (bc) => _action(
                  Icons.send_outlined,
                  'Enviar al cliente',
                  () => compartir(bc, mensajeHallazgo(widget.inspection, widget.section, it, r), fotos: r.fotos),
                  strong: true,
                ),
              ),
          ]),
        ]),
      ),
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onTap, {bool strong = false}) => TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 19),
        label: Text(label, style: TextStyle(fontWeight: strong ? FontWeight.w700 : FontWeight.w500)),
        style: TextButton.styleFrom(
          foregroundColor: strong ? C.gold700 : C.green700,
          padding: const EdgeInsets.symmetric(horizontal: 6),
        ),
      );

  Widget _optButton(Opt opt, int index) {
    final on = r.opt == index;
    final color = C.sevColor(opt.sev);
    return Material(
      color: on ? color : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            r.opt = on ? null : index;
            // Si marca un problema, abre el comentario para que lo explique.
            if (!on && opt.sev > 0) _showNota = true;
            if (r.opt == null || opt.sev <= 0) {
              r.costo = null;
              _costo.clear();
            }
          });
          _changed();
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: on ? color : C.line, width: 1.5),
          ),
          child: Text(opt.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: it.opts.length > 3 ? 12.5 : 13.5,
                  height: 1.15,
                  color: on ? Colors.white : C.text)),
        ),
      ),
    );
  }
}
