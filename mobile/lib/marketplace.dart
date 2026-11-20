import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import 'checklist.dart';
import 'danos.dart';
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

  static const _nativo = MethodChannel('atlas/video');

  /// Versión de la marca de agua: si cambia, los videos se vuelven a subir.
  static const _versionMarca = 'm1';

  /// El escudo de la marca de agua, copiado a un archivo para el código nativo.
  static Future<String> _logo() async {
    final f = File('${(await getTemporaryDirectory()).path}/marca-escudo.png');
    if (!await f.exists()) {
      await f.writeAsBytes((await rootBundle.load('assets/marca-escudo.png')).buffer.asUint8List());
    }
    return f.path;
  }

  /// Copia de la foto con la marca de agua de Atlas Motors.
  static Future<File> _marcarFoto(File foto, String salida) async {
    try {
      await _nativo.invokeMethod('marcarFoto', {'path': foto.path, 'salida': salida, 'logo': await _logo()});
      return File(salida);
    } catch (e) {
      debugPrint('Marca de agua: $e');
      throw 'No se pudo poner la marca de agua a una foto. Intenta de nuevo.';
    }
  }

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
      final marcada = await _marcarFoto(File(out?.path ?? original.path), '${tmp.path}/pub-m-$f');
      final ref = carpeta.child(f);
      await ref.putFile(marcada,
          SettableMetadata(contentType: 'image/jpeg', cacheControl: 'public, max-age=31536000'));
      urls.add(await ref.getDownloadURL());
    }

    // Videos: ya vienen comprimidos a 720p. La miniatura va como portada del reproductor.
    final videos = <Map<String, dynamic>>[];
    final elegidos = [for (final a in v.videos) ...i.videos.where((x) => x.archivo == a)];
    for (final (n, video) in elegidos.indexed) {
      avance('Revisando video ${n + 1} de ${elegidos.length}…');
      final File archivo;
      try {
        archivo = await Store.I.archivoVideo(i, video);
      } catch (_) {
        throw 'Uno de los videos elegidos no está en este teléfono ni en la nube. Quítalo o publícalo desde el teléfono donde se grabó.';
      }
      final ref = carpeta.child(video.archivo);
      // Si ya se subió en una publicación anterior (mismo video y misma marca),
      // no se vuelve a procesar ni a subir: pesa varios MB.
      final fuente = '${video.archivo}-${archivo.lengthSync()}-$_versionMarca';
      final yaEsta = await ref.getMetadata().then((m) => m.customMetadata?['fuente'] == fuente, onError: (_) => false);
      if (!yaEsta) {
        avance('Poniendo la marca de agua al video ${n + 1}…');
        final marcado = '${tmp.path}/pub-${video.archivo}';
        try {
          await _nativo.invokeMethod('comprimir', {'path': archivo.path, 'salida': marcado, 'logo': await _logo()})
              .timeout(const Duration(minutes: 3));
        } catch (e) {
          debugPrint('Marca de agua en video: $e');
          throw 'No se pudo poner la marca de agua a un video. Intenta de nuevo o quítalo de la publicación.';
        }
        avance('Subiendo video ${n + 1} de ${elegidos.length}…');
        await ref.putFile(File(marcado), SettableMetadata(
            contentType: 'video/mp4', cacheControl: 'public, max-age=31536000', customMetadata: {'fuente': fuente}));
        await File(marcado).delete();
      }
      String? poster;
      final mini = Store.I.photoFile(video.miniatura);
      if (video.miniatura.isNotEmpty && await mini.exists()) {
        final posterRef = carpeta.child(video.miniatura);
        await posterRef.putFile(await _marcarFoto(mini, '${tmp.path}/pub-m-${video.miniatura}'), SettableMetadata(contentType: 'image/jpeg', cacheControl: 'public, max-age=31536000'));
        poster = await posterRef.getDownloadURL();
      }
      videos.add({'url': await ref.getDownloadURL(), 'poster': poster, 'nota': video.nota.trim(), 'segundos': video.segundos});
    }

    avance('Armando la ficha PDF…');
    var k = 0;
    final pdf = await buildFicha(i, marcar: (bytes) async {
      final f = File('${tmp.path}/ficha-${k++}.jpg');
      await f.writeAsBytes(bytes);
      return (await _marcarFoto(f, '${f.path}.m.jpg')).readAsBytes();
    });
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
      // Mapa de daños: pieza, tipo, gravedad y dónde se marcó (la web lo dibuja).
      'danos': [
        for (final d in i.danos.take(60))
          {'zona': d.zona, 'pieza': d.nombreZona, 'tipo': d.nombreTipo, 'nivel': d.sev, 'x': d.x.round(), 'y': d.y.round()},
      ],
      // El dibujo listo (trazos SVG), para que la web lo muestre igual que la app.
      if (i.carroceria.isNotEmpty || i.danos.isNotEmpty) 'mapa': mapaDe(i.carroceria).toJson(),
      'fotos': urls,
      'videos': videos,
      'ficha': ficha,
      'fechaInspeccion': Timestamp.fromDate(i.fecha),
      'publicado': v.publicada == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(v.publicada!),
      'actualizado': FieldValue.serverTimestamp(),
    });

    // Fotos que ya no están en la publicación: se borran de la carpeta pública.
    try {
      final quedan = {
        ...v.fotos,
        for (final video in elegidos) ...[video.archivo, if (video.miniatura.isNotEmpty) video.miniatura],
        'ficha.pdf',
      };
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
