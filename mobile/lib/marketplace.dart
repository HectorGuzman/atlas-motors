import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import 'checklist.dart';
import 'screens/report.dart' show buildFicha;
import 'store.dart';

/// Publica autos en el marketplace de atlasmotors.cl.
///
/// - Firestore `publicaciones/{inspección}`: lo que muestra la web (lectura pública).
/// - Storage `publicaciones/{inspección}/...` (bucket atlas-motors-cl-fotos):
///   fotos reducidas y la ficha PDF, con enlaces de descarga públicos.
///
/// No se publica la patente ni los datos del dueño.
class Marketplace {
  static const web = 'https://www.atlasmotors.cl';
  static String enlace(Inspection i) => '$web/#/auto/${i.id}';

  static Reference _carpeta(Inspection i) =>
      FirebaseStorage.instanceFor(bucket: 'gs://atlas-motors-cl-fotos').ref('publicaciones/${i.id}');
  static DocumentReference<Map<String, dynamic>> _doc(Inspection i) =>
      FirebaseFirestore.instance.collection('publicaciones').doc(i.id);

  /// Sube fotos y ficha, y publica (o actualiza) el aviso. Lanza un error con
  /// un mensaje para mostrar si algo falla.
  static Future<void> publicar(Inspection i, void Function(String) avance) async {
    final v = i.venta!;
    final carpeta = _carpeta(i);
    final tmp = await getTemporaryDirectory();

    final urls = <String>[];
    for (final (n, f) in v.fotos.indexed) {
      avance('Subiendo foto ${n + 1} de ${v.fotos.length}…');
      final original = Store.I.photoFile(f);
      if (!await original.exists()) {
        throw 'Una de las fotos elegidas no está en este teléfono. Espera a que se descargue o quítala.';
      }
      // 1600 px de ancho como máximo: se ve bien en pantalla grande y pesa poco.
      final reducida = File('${tmp.path}/pub-$f');
      final out = await FlutterImageCompress.compressAndGetFile(original.path, reducida.path,
          minWidth: 1600, minHeight: 1200, quality: 72, keepExif: false);
      final ref = carpeta.child(f);
      await ref.putFile(File(out?.path ?? original.path),
          SettableMetadata(contentType: 'image/jpeg', cacheControl: 'public, max-age=31536000'));
      urls.add(await ref.getDownloadURL());
    }

    avance('Armando la ficha PDF…');
    final pdf = await buildFicha(i);
    final fichaRef = carpeta.child('ficha.pdf');
    await fichaRef.putData(pdf, SettableMetadata(contentType: 'application/pdf', cacheControl: 'no-cache'));
    final ficha = await fichaRef.getDownloadURL();

    avance('Publicando…');
    final km = int.tryParse(i.km);
    await _doc(i).set({
      'id': i.id,
      'folio': i.folio,
      'marca': i.marca,
      'modelo': i.modelo,
      'anio': int.tryParse(i.anio) ?? i.anio,
      'km': km,
      'precio': v.precio,
      'comuna': v.comuna.trim(),
      'combustible': v.combustible,
      'transmision': v.transmision,
      'descripcion': v.descripcion.trim(),
      'comentario': v.comentario.trim(),
      'puntaje': i.score,
      'recomendacion': i.recomendacion == null ? null : recomendaciones[i.recomendacion!],
      'nivel': i.recomendacion,
      'conteo': {'bien': i.counts()[0], 'obs': i.counts()[1], 'problema': i.counts()[2]},
      'etapas': [
        for (final s in checklist)
          if (i.answeredIn(s) > 0)
            {'titulo': s.title, 'bien': i.counts(s)[0], 'obs': i.counts(s)[1], 'problema': i.counts(s)[2]},
      ],
      'hallazgos': [
        for (final h in i.hallazgos) {'punto': h.item.label, 'etapa': h.section.title, 'estado': h.opt.label, 'nivel': h.opt.sev},
      ],
      'fotos': urls,
      'ficha': ficha,
      'fechaInspeccion': Timestamp.fromDate(i.fecha),
      'publicado': v.publicada == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(v.publicada!),
      'actualizado': FieldValue.serverTimestamp(),
    });

    // Fotos que ya no están en la publicación: se borran de la carpeta pública.
    try {
      final quedan = {...v.fotos, 'ficha.pdf'};
      for (final item in (await carpeta.listAll()).items) {
        if (!quedan.contains(item.name)) await item.delete();
      }
    } catch (e) {
      debugPrint('No se pudieron limpiar fotos viejas: $e');
    }

    v.publicada ??= DateTime.now();
    await Store.I.save(i);
  }

  /// Quita el aviso de la web (las fotos de la inspección no se tocan).
  static Future<void> despublicar(Inspection i) async {
    await _doc(i).delete();
    try {
      for (final item in (await _carpeta(i).listAll()).items) {
        await item.delete();
      }
    } catch (e) {
      debugPrint('No se pudieron borrar los archivos públicos: $e');
    }
    i.venta?.publicada = null;
    await Store.I.save(i);
  }
}
