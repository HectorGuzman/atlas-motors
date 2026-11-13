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
    if (total != null) {
      b.write('\nReparaciones estimadas: *${clp(total)}* (referencial). Te sirve como respaldo para negociar el precio.');
    }
  }
  if (i.recomendacion != null) b.write('\n\n*${recomendaciones[i.recomendacion!]}*');
  if (i.conclusion.trim().isNotEmpty) b.write('\n${i.conclusion.trim()}');
  b.write('\n\nEl informe completo en PDF va a continuación.');
  return b.toString();
}

/// Abre el menú de compartir del iPhone (WhatsApp, etc.).
Future<void> compartir(BuildContext context, String texto, {List<String> fotos = const []}) async {
  final box = context.findRenderObject() as RenderBox?;
  await SharePlus.instance.share(ShareParams(
    text: texto,
    // share_plus rechaza una lista vacía: sin fotos se manda solo el texto.
    files: fotos.isEmpty ? null : [for (final f in fotos) XFile(Store.I.photoFile(f).path)],
    sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
  ));
}
