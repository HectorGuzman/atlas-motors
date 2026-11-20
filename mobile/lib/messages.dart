import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

import 'checklist.dart';
import 'store.dart';
import 'theme.dart';

/// Mensajes para el cliente, pensados para WhatsApp. Sirven sobre todo en la
/// inspección remota: Matías va mandando cada hallazgo con su foto mientras revisa.

String mensajeHallazgo(Inspection i, Section s, Item it, ItemResult r) {
  final b = StringBuffer('*Atlas Motors · ${i.vehiculo}*\n');
  b.write('${s.title} · ${it.label}: *${it.opts[r.opt!].label}*');
  if (r.nota.trim().isNotEmpty) b.write('\n${r.nota.trim()}');
  if (r.costo != null) b.write('\nCosto estimado de reparación: ${clp(r.costo!)} (referencial)');
  return b.toString();
}

String mensajeResumen(Inspection i) {
  final b = StringBuffer('*Atlas Motors · Resumen de inspección*\n${i.vehiculo}');
  if (i.patente.isNotEmpty) b.write(' · ${i.patente}');
  b.write('\n');
  final hs = i.hallazgos;
  if (hs.isEmpty) {
    b.write('\nNo encontramos observaciones en los puntos revisados.');
  } else {
    final graves = hs.where((h) => h.opt.sev == 2).toList();
    final leves = hs.where((h) => h.opt.sev == 1).toList();
    if (graves.isNotEmpty) {
      b.write('\n*Fallas importantes*');
      for (final h in graves) {
        b.write('\n• ${h.item.label}: ${h.opt.label}');
        if (h.result.nota.trim().isNotEmpty) b.write(' — ${h.result.nota.trim()}');
        if (h.result.costo != null) b.write(' (~${clp(h.result.costo!)})');
      }
      b.write('\n');
    }
    if (leves.isNotEmpty) {
      b.write('\n*Detalles*');
      for (final h in leves) {
        b.write('\n• ${h.item.label}: ${h.opt.label}');
        if (h.result.nota.trim().isNotEmpty) b.write(' — ${h.result.nota.trim()}');
        if (h.result.costo != null) b.write(' (~${clp(h.result.costo!)})');
      }
      b.write('\n');
    }
    final total = i.costoTotal;
    if (i.danos.isNotEmpty) {
      b.write('\n*Carrocería* (ver mapa en el informe)');
      for (final d in i.danos) {
        b.write('\n• ${d.nombreZona}: ${d.nombreTipo.toLowerCase()}');
        if (d.nota.trim().isNotEmpty) b.write(' — ${d.nota.trim()}');
      }
      b.write('\n');
    }
    if (total != null) {
      b.write('\nReparaciones estimadas: *${clp(total)}* (referencial). Te sirve como respaldo para negociar el precio.');
    }
  }
  if (i.recomendacion != null) b.write('\n\n*${recomendaciones[i.recomendacion!]}*');
  if (i.conclusion.trim().isNotEmpty) b.write('\n${i.conclusion.trim()}');
  b.write('\n\nEl informe completo en PDF va a continuación.');
  return b.toString();
}

/// Texto que acompaña al informe PDF cuando se le manda al cliente.
String mensajeInforme(Inspection i) {
  final nombre = i.cliente.trim().isEmpty ? '' : ' ${i.cliente.trim().split(RegExp(r'\s+')).first}';
  final auto = [i.vehiculo, if (i.patente.isNotEmpty) 'patente ${i.patente}'].where((t) => t.isNotEmpty).join(', ');
  return '¡Hola$nombre! 👋\n\n'
      'Terminamos la inspección${auto.isEmpty ? '' : ' del *$auto*'} y nos da gusto enviarte el informe completo en PDF, '
      'con el checklist, las fotos de lo que encontramos y nuestra recomendación.\n\n'
      'Ojalá te ayude a tomar la mejor decisión para tu compra. Si tienes cualquier duda sobre el informe, '
      'escríbenos por aquí y te la explicamos con gusto.\n\n'
      'Gracias por confiar en Atlas Motors. Cuenta con nosotros para tus próximas compras, y si alguien '
      'que conoces está buscando auto, ¡recomiéndanos! 🚗\n\n'
      'Si te sirvió, tu opinión en Google nos ayuda mucho a seguir creciendo:\n'
      'https://www.google.com/maps?cid=15933301111320184842\n\n'
      '*Atlas Motors* · atlasmotors.cl';
}

/// Abre el menú de compartir del iPhone (WhatsApp, etc.).
Future<void> compartir(BuildContext context, String texto, {List<String> fotos = const []}) async {
  final box = context.findRenderObject() as RenderBox?;
  // Solo las fotos que están en este teléfono.
  fotos = [for (final f in fotos) if (Store.I.photoFile(f).existsSync()) f];
  await SharePlus.instance.share(ShareParams(
    text: texto,
    // share_plus rechaza una lista vacía: sin fotos se manda solo el texto.
    files: fotos.isEmpty ? null : [for (final f in fotos) XFile(Store.I.photoFile(f).path)],
    sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
  ));
}
