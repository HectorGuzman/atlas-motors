import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../checklist.dart';
import '../marketplace.dart';
import '../store.dart';
import '../theme.dart';

/// Trabajos hechos al auto después de la inspección (por ejemplo, neumáticos
/// nuevos), con su boleta. Salen en el informe PDF y, si el auto está a la
/// venta, en atlasmotors.cl. Solo los admin ven las inspecciones.
class ActualizacionesCard extends StatelessWidget {
  final Inspection i;
  const ActualizacionesCard(this.i, {super.key});

  Future<void> _abrir(BuildContext context, [Actualizacion? a]) async {
    final cambio = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => ActualizacionScreen(inspection: i, actualizacion: a)));
    if (cambio == true && context.mounted) await ofrecerActualizarWeb(context, i);
  }

  @override
  Widget build(BuildContext context) {
    final lista = [...i.actualizaciones]..sort((a, b) => b.fecha.compareTo(a.fecha));
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.build_circle_outlined, color: C.gold700),
            const SizedBox(width: 8),
            Expanded(child: Text('Después de la inspección', style: display(17))),
          ]),
          const SizedBox(height: 4),
          const Text('Trabajos hechos al auto después de inspeccionarlo, con su boleta. Salen en el informe y en la web.',
              style: TextStyle(color: C.muted, fontSize: 13)),
          for (final a in lista)
            ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: () => _abrir(context, a),
              leading: CircleAvatar(
                backgroundColor: C.sevBg[0],
                child: Icon(Icons.check, color: C.sev[0]),
              ),
              title: Text(a.texto.trim().isEmpty ? 'Sin descripción' : a.texto.trim(),
                  maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text([
                DateFormat('d MMM y', 'es').format(a.fecha),
                ?labelDe(a.item),
                if (a.fotos.isNotEmpty) a.fotos.length == 1 ? '1 respaldo' : '${a.fotos.length} respaldos',
              ].join(' · ')),
              trailing: const Icon(Icons.chevron_right),
            ),
          TextButton.icon(
            onPressed: () => _abrir(context),
            icon: const Icon(Icons.add),
            label: const Text('Agregar trabajo realizado'),
          ),
        ]),
      ),
    );
  }
}

/// Nombre del punto del checklist, o null.
String? labelDe(String? itemId) {
  if (itemId == null) return null;
  for (final s in checklist) {
    for (final it in s.items) {
      if (it.id == itemId) return it.label;
    }
  }
  return null;
}

/// Si el auto está publicado, pregunta si actualizar el informe en la web.
Future<void> ofrecerActualizarWeb(BuildContext context, Inspection i) async {
  if (i.venta?.publicada == null) return;
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('¿Actualizar la web?'),
      content: const Text('Este auto está publicado en atlasmotors.cl. ¿Actualizo ahora el informe y la ficha PDF?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Después')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Actualizar')),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  final avance = ValueNotifier('Preparando…');
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (c) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(children: [
          const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
          const SizedBox(width: 16),
          Expanded(child: ValueListenableBuilder(valueListenable: avance, builder: (_, t, _) => Text(t))),
        ]),
      ),
    ),
  );
  String mensaje;
  try {
    await Store.I.guardarPendiente();
    await Marketplace.actualizarInforme(i, (t) => avance.value = t);
    mensaje = 'Listo, la web ya muestra el informe actualizado.';
  } catch (e) {
    mensaje = e is String ? e : 'No se pudo actualizar la web. Inténtalo desde "Vender este auto".';
  }
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  avance.dispose();
}

class ActualizacionScreen extends StatefulWidget {
  final Inspection inspection;
  final Actualizacion? actualizacion; // null = nueva
  const ActualizacionScreen({super.key, required this.inspection, this.actualizacion});
  @override
  State<ActualizacionScreen> createState() => _ActualizacionScreenState();
}

class _ActualizacionScreenState extends State<ActualizacionScreen> {
  Inspection get i => widget.inspection;
  bool get nueva => widget.actualizacion == null;
  late final Actualizacion a = widget.actualizacion ??
      Actualizacion(id: '${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(999)}', fecha: DateTime.now());
  late final _texto = TextEditingController(text: a.texto);
  late DateTime _fecha = a.fecha;
  late String? _item = a.item;
  late final List<String> _fotos = [...a.fotos];

  /// Fotos agregadas en esta pantalla: si se cancela, se borran.
  final _nuevas = <String>[];

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _foto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final xs = source == ImageSource.camera
          ? [?await picker.pickImage(source: source, maxWidth: 2000, imageQuality: 82)]
          : await picker.pickMultiImage(maxWidth: 2000, imageQuality: 82);
      for (final x in xs) {
        final n = await Store.I.addPhoto(x.path, i);
        _nuevas.add(n);
        _fotos.add(n);
      }
      if (mounted) setState(() {});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(source == ImageSource.camera ? 'No se pudo abrir la cámara.' : 'No se pudo abrir la galería.')));
    }
  }

  Future<void> _elegirFecha() async {
    final f = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(i.fecha.year, i.fecha.month, i.fecha.day),
      lastDate: DateTime.now(),
    );
    if (f != null) setState(() => _fecha = f);
  }

  Future<void> _guardar() async {
    if (_texto.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Escribe qué se hizo. Ej. "Se cambiaron los 4 neumáticos".')));
      return;
    }
    a
      ..texto = _texto.text.trim()
      ..fecha = _fecha
      ..item = _item;
    // Las fotos que se quitaron se borran del teléfono.
    for (final f in {...a.fotos, ..._nuevas}.where((f) => !_fotos.contains(f)).toList()) {
      await Store.I.removePhoto(i, a.fotos, f);
    }
    a.fotos
      ..clear()
      ..addAll(_fotos);
    if (nueva) i.actualizaciones.add(a);
    await Store.I.save(i);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _cancelar() async {
    for (final f in _nuevas) {
      await Store.I.removePhoto(i, _fotos, f);
    }
    if (mounted) Navigator.pop(context, false);
  }

  Future<void> _eliminar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('¿Eliminar este trabajo?'),
        content: const Text('Se borra del informe junto con sus fotos de respaldo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: C.bad),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;
    for (final f in {...a.fotos, ..._fotos}.toList()) {
      await Store.I.removePhoto(i, a.fotos, f);
    }
    i.actualizaciones.remove(a);
    await Store.I.save(i);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final hallazgos = i.hallazgos;
    final opciones = <String?, String>{
      for (final h in hallazgos) h.item.id: '${h.item.label} · ${h.opt.label}',
      if (_item != null && !hallazgos.any((h) => h.item.id == _item)) _item: labelDe(_item) ?? 'Otro punto',
      null: 'Otro trabajo (sin punto de la inspección)',
    };
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (popped, _) {
        if (!popped) _cancelar();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(nueva ? 'Trabajo realizado' : 'Editar trabajo'),
          actions: [
            if (!nueva) IconButton(tooltip: 'Eliminar', icon: const Icon(Icons.delete_outline), onPressed: _eliminar),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: GoldButton('Guardar', icon: Icons.check, onPressed: _guardar),
          ),
        ),
        body: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text('¿Qué punto corrige?', style: display(17)),
            const SizedBox(height: 4),
            const Text('El resultado original de la inspección se mantiene; el punto se muestra como corregido.',
                style: TextStyle(color: C.muted, fontSize: 13)),
            const SizedBox(height: 8),
            RadioGroup<String?>(
              groupValue: _item,
              onChanged: (v) => setState(() => _item = v),
              child: Column(children: [
                for (final e in opciones.entries)
                  RadioListTile<String?>(
                    value: e.key,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(e.value),
                  ),
              ]),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _texto,
              minLines: 2,
              maxLines: 5,
              maxLength: 300,
              textCapitalization: TextCapitalization.sentences,
              onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              decoration: const InputDecoration(
                  labelText: '¿Qué se hizo?', hintText: 'Ej. Se cambiaron los 4 neumáticos en Neumáticos La Serena.'),
            ),
            const SizedBox(height: 6),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined, color: C.gold700),
              title: const Text('Fecha del trabajo'),
              subtitle: Text(DateFormat("d 'de' MMMM 'de' y", 'es').format(_fecha)),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _elegirFecha,
            ),
            const SizedBox(height: 10),
            Text('Respaldo', style: display(17)),
            const SizedBox(height: 4),
            const Text('Foto de la boleta, la factura o el trabajo. Va en el informe del cliente; en la web solo se dice que hay respaldo.',
                style: TextStyle(color: C.muted, fontSize: 13)),
            const SizedBox(height: 10),
            if (_fotos.isNotEmpty)
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _fotos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, n) => Stack(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(Store.I.photoFile(_fotos[n]), width: 96, height: 96, fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(width: 96, height: 96, color: C.cream2,
                              child: const Icon(Icons.cloud_download_outlined, color: C.muted))),
                    ),
                    Positioned(
                      right: 2,
                      top: 2,
                      child: IconButton.filledTonal(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Quitar',
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => setState(() => _fotos.removeAt(n)),
                      ),
                    ),
                  ]),
                ),
              ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _foto(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Tomar foto'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _foto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galería'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
