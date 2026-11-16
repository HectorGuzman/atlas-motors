import 'dart:io';
import 'package:atlas_inspecciones/checklist.dart';
import 'package:atlas_inspecciones/screens/report.dart';
import 'package:atlas_inspecciones/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  test('genera el informe PDF', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('es');
    final i = Inspection(id: 't', folio: 'ATM-261110-101', fecha: DateTime(2026, 11, 10), cliente: 'Cliente de ejemplo',
        marca: 'Mitsubishi', modelo: 'L200', anio: '2020', patente: 'LXJR-55', km: '78400', lugar: 'Coquimbo',
        inspector: 'Matías', recomendacion: 1, modalidad: 1,
        conclusion: 'Camioneta de trabajo con uso acorde a su kilometraje. Mecánica sana. Negociar por el embrague.');
    for (final s in checklist) { for (final it in s.items) { i.results[it.id] = ItemResult(opt: 0); } }
    i.results['ruta.embrague'] = ItemResult(opt: 2, nota: 'Patina en tercera y cuarta bajo carga.', costo: 450000);
    i.results['motor.correas'] = ItemResult(opt: 1, nota: 'Correa de accesorios con grietas.', costo: 60000);
    i.results['esc.caja'] = ItemResult(opt: 3);
    i.results.remove('doc.soap');
    final dir = Directory.systemTemp.createTempSync('atlas');
    Store.I.usarCarpeta(dir);
    final mini = Platform.environment['MINI_JPG'];
    if (mini != null) {
      Directory('${dir.path}/fotos').createSync();
      File(mini).copySync('${dir.path}/fotos/v1.jpg');
    }
    // Un video subido (sale con QR) y uno pendiente de subir.
    i.videos.add(Video(archivo: 'v1.mp4', miniatura: 'v1.jpg', nota: 'Ruido metálico al girar', item: 'ruta.embrague',
        segundos: 18, url: 'https://firebasestorage.googleapis.com/v0/b/atlas-motors-cl-fotos/o/videos%2Ft%2Fv1.mp4'));
    i.videos.add(Video(archivo: 'v2.mp4', miniatura: 'v2.jpg', segundos: 9));
    final bytes = await run(() => buildReport(i));
    final out = Platform.environment['PDF_OUT'];
    if (out != null) File(out).writeAsBytesSync(bytes);
    expect(bytes.length, greaterThan(10000));
    expect(i.score, isNotNull);
    expect(i.costoTotal, 510000);
    expect(i.tieneFallasGraves, isTrue);
    expect(i.hallazgos.first.item.id, 'ruta.embrague'); // lo grave primero

    // Ficha pública para el marketplace.
    i.venta = Venta(precio: 17990000, comuna: 'Coquimbo', combustible: 'Diésel', transmision: 'Manual',
        comentario: i.conclusion, autorizada: true);
    final ficha = await buildFicha(i);
    expect(ficha.length, greaterThan(10000));
    // La venta viaja con la inspección (se respalda y sincroniza).
    final copia = Inspection.fromJson(i.toJson());
    expect(copia.venta?.precio, 17990000);
    expect(copia.venta?.publicada, isNull);
    expect(copia.videos.length, 2);
    expect(copia.videos.first.item, 'ruta.embrague');
    expect(copia.videosDe('ruta.embrague').single.url, startsWith('https://'));
    expect(copia.todasLasFotos, containsAll(['v1.jpg', 'v2.jpg']));
  });
}

Future<T> run<T>(Future<T> Function() f) => f();
