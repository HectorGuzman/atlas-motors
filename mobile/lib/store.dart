import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'checklist.dart';

class ItemResult {
  int? opt; // índice de la opción elegida
  String nota;
  int? costo; // costo estimado de reparación en CLP (referencial, para negociar)
  List<String> fotos; // nombres de archivo dentro de la carpeta de fotos
  ItemResult({this.opt, this.nota = '', this.costo, List<String>? fotos}) : fotos = fotos ?? [];

  bool get isEmpty => opt == null && nota.isEmpty && costo == null && fotos.isEmpty;
  Map<String, dynamic> toJson() => {'opt': opt, 'nota': nota, 'costo': costo, 'fotos': fotos};
  factory ItemResult.fromJson(Map<String, dynamic> j) => ItemResult(
      opt: j['opt'], nota: j['nota'] ?? '', costo: j['costo'], fotos: List<String>.from(j['fotos'] ?? []));
}

/// Un punto con observación o problema, para el resumen y el informe.
class Hallazgo {
  final Section section;
  final Item item;
  final ItemResult result;
  Hallazgo(this.section, this.item, this.result);
  Opt get opt => item.opts[result.opt!];
}

/// Cómo se hizo la inspección.
const modalidades = ['Presencial', 'Remota'];
const modalidadDetalle = [
  'El cliente estuvo presente.',
  'El cliente no estuvo presente: la inspección se grabó y los hallazgos se le enviaron con foto durante la revisión.',
];

const recomendaciones = ['Compra recomendada', 'Compra con observaciones', 'Compra no recomendada'];

class Inspection {
  String id, folio;
  DateTime fecha;
  String cliente, telefono, marca, modelo, anio, patente, km, lugar, inspector;
  String conclusion;
  int? recomendacion;
  int modalidad; // índice en [modalidades]
  Map<String, ItemResult> results;
  DateTime actualizado; // último cambio, para decidir qué copia gana al sincronizar

  Inspection({
    required this.id,
    required this.folio,
    required this.fecha,
    this.cliente = '',
    this.telefono = '',
    this.marca = '',
    this.modelo = '',
    this.anio = '',
    this.patente = '',
    this.km = '',
    this.lugar = '',
    this.inspector = '',
    this.conclusion = '',
    this.recomendacion,
    this.modalidad = 0,
    Map<String, ItemResult>? results,
    DateTime? actualizado,
  })  : results = results ?? {},
        actualizado = actualizado ?? fecha;

  String get vehiculo => [marca, modelo, anio].where((s) => s.isNotEmpty).join(' ');
  ItemResult result(String itemId) => results.putIfAbsent(itemId, () => ItemResult());

  int get respondidos => results.values.where((r) => r.opt != null).length;
  bool get completa => respondidos == totalItems;

  /// Cuenta respuestas por gravedad: [bien, observación, problema].
  List<int> counts([Section? only]) {
    final c = [0, 0, 0];
    for (final s in checklist) {
      if (only != null && s.id != only.id) continue;
      for (final it in s.items) {
        final o = results[it.id]?.opt;
        if (o != null && o < it.opts.length && it.opts[o].sev >= 0) c[it.opts[o].sev]++;
      }
    }
    return c;
  }

  /// Observaciones y problemas, de lo más grave a lo menos grave, en orden de recorrido.
  List<Hallazgo> get hallazgos {
    final out = <Hallazgo>[];
    for (final s in checklist) {
      for (final it in s.items) {
        final r = results[it.id];
        if (r?.opt != null && r!.opt! < it.opts.length && it.opts[r.opt!].sev > 0) out.add(Hallazgo(s, it, r));
      }
    }
    out.sort((a, b) => b.opt.sev.compareTo(a.opt.sev));
    return out;
  }

  /// Suma de los costos estimados de reparación (null si no hay ninguno).
  int? get costoTotal {
    final cs = hallazgos.map((h) => h.result.costo).whereType<int>();
    return cs.isEmpty ? null : cs.reduce((a, b) => a + b);
  }

  bool get tieneFallasGraves => hallazgos.any((h) => h.opt.sev == 2);

  int answeredIn(Section s) => s.items.where((it) => results[it.id]?.opt != null).length;

  /// Puntaje 0-100 sobre lo respondido (bien = 1, observación = 0,5, problema = 0).
  int? get score {
    final c = counts();
    final n = c[0] + c[1] + c[2];
    if (n == 0) return null;
    return ((c[0] + c[1] * 0.5) / n * 100).round();
  }

  Map<String, dynamic> toJson() => {
        'id': id, 'folio': folio, 'fecha': fecha.toIso8601String(), 'cliente': cliente, 'telefono': telefono,
        'marca': marca, 'modelo': modelo, 'anio': anio, 'patente': patente, 'km': km, 'lugar': lugar,
        'inspector': inspector, 'conclusion': conclusion, 'recomendacion': recomendacion, 'modalidad': modalidad,
        'results': {
          for (final e in results.entries)
            if (!e.value.isEmpty) e.key: e.value.toJson()
        },
      };

  factory Inspection.fromJson(Map<String, dynamic> j) => Inspection(
        id: j['id'], folio: j['folio'], fecha: DateTime.parse(j['fecha']),
        cliente: j['cliente'] ?? '', telefono: j['telefono'] ?? '', marca: j['marca'] ?? '',
        modelo: j['modelo'] ?? '', anio: j['anio'] ?? '', patente: j['patente'] ?? '', km: j['km'] ?? '',
        lugar: j['lugar'] ?? '', inspector: j['inspector'] ?? '', conclusion: j['conclusion'] ?? '',
        recomendacion: j['recomendacion'],
        modalidad: j['modalidad'] ?? 0,
        results: (j['results'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, ItemResult.fromJson(Map<String, dynamic>.from(v)))),
        actualizado: j['actualizado'] == null ? null : DateTime.parse(j['actualizado']),
      );

  /// Copia local completa (incluye la fecha del último cambio).
  Map<String, dynamic> toLocalJson() => {...toJson(), 'actualizado': actualizado.toIso8601String()};
}

/// Estado de la app.
/// - Login con Firebase Auth (correo y clave).
/// - Las inspecciones se guardan en el teléfono (funciona sin señal) y se
///   respaldan en Firestore, colección `inspecciones`. Al abrir la app o
///   iniciar sesión se trae lo de la nube y gana la copia modificada más tarde.
/// - Las fotos se guardan en el teléfono y se suben a Cloud Storage
///   (bucket `atlas-motors-cl-fotos`, ruta fotos/{inspección}/{archivo}).
///   Las que no alcanzan a subir quedan en cola; las que faltan en este
///   teléfono se descargan al sincronizar.
class Store extends ChangeNotifier {
  Store._();
  static final Store I = Store._();

  static const _ejemploId = 'ejemplo';

  late Directory _dir;
  List<Inspection> inspections = [];
  String? userEmail;

  /// Lo último que se mandó a la nube por inspección, para subir solo lo que cambió.
  final Map<String, String> _enNube = {};

  FirebaseAuth get _auth => FirebaseAuth.instance;
  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore.instance.collection('inspecciones');
  Reference get _fotosNube => FirebaseStorage.instanceFor(bucket: 'gs://atlas-motors-cl-fotos').ref('fotos');

  /// Fotos por subir: "inspección/archivo". Se guarda en disco para reintentar.
  Set<String> _porSubir = {};
  bool _subiendo = false;
  File get _colaFile => File('${_dir.path}/fotos-por-subir.json');

  String get userName {
    final n = (userEmail ?? '').split('@').first.replaceAll(RegExp(r'[._]'), ' ').trim();
    return n.isEmpty ? 'Inspector' : n[0].toUpperCase() + n.substring(1);
  }

  // v2: checklist reordenado según el recorrido de Matías (ids nuevos).
  File get _file => File('${_dir.path}/inspecciones-v2.json');
  File photoFile(String name) => File('${_dir.path}/fotos/$name');

  Future<void> init() async {
    _dir = await getApplicationDocumentsDirectory();
    await Directory('${_dir.path}/fotos').create(recursive: true);
    // Limpia la sesión falsa de la versión sin servidor.
    (await SharedPreferences.getInstance()).remove('email');
    if (await _file.exists()) {
      final list = jsonDecode(await _file.readAsString()) as List;
      inspections = list.map((e) => Inspection.fromJson(Map<String, dynamic>.from(e))).toList();
    } else {
      inspections = [_ejemplo()];
      await _writeLocal();
    }
    if (await _colaFile.exists()) {
      _porSubir = Set<String>.from(jsonDecode(await _colaFile.readAsString()) as List);
    }
    userEmail = _auth.currentUser?.email;
    if (userEmail != null) unawaited(sync());
  }

  /// Inicia sesión. Devuelve un mensaje de error para mostrar, o null si entró.
  Future<String?> login(String email, String clave) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: clave);
    } on FirebaseAuthException catch (e) {
      return switch (e.code) {
        'invalid-email' => 'El correo no es válido.',
        'user-disabled' => 'Esta cuenta está desactivada.',
        'too-many-requests' => 'Demasiados intentos. Espera unos minutos y vuelve a intentar.',
        'network-request-failed' => 'Sin conexión. Revisa tu señal e intenta de nuevo.',
        _ => 'Correo o clave incorrectos.',
      };
    }
    userEmail = _auth.currentUser?.email;
    notifyListeners();
    unawaited(sync());
    return null;
  }

  /// Manda un correo para crear una clave nueva. Devuelve un error o null.
  Future<String?> recuperarClave(String email) async {
    try {
      await _auth.setLanguageCode('es');
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return e.code == 'invalid-email' ? 'El correo no es válido.' : 'No pudimos enviar el correo. Intenta de nuevo.';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    userEmail = null;
    notifyListeners();
  }

  Future<void> _writeLocal() =>
      _file.writeAsString(jsonEncode(inspections.map((i) => i.toLocalJson()).toList()));

  /// Guarda en el teléfono y sube a la nube lo que cambió.
  /// Firestore deja los cambios en cola si no hay señal y los sube después.
  Future<void> save() async {
    final now = DateTime.now();
    for (final i in inspections) {
      if (i.id == _ejemploId) continue;
      final json = jsonEncode(i.toJson());
      if (_enNube[i.id] == json) continue;
      if (_enNube.containsKey(i.id)) i.actualizado = now;
      _enNube[i.id] = json;
      _subir(i);
    }
    await _writeLocal();
    notifyListeners();
  }

  void _subir(Inspection i) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    _col.doc(i.id).set({
      ...i.toJson(),
      'actualizado': Timestamp.fromDate(i.actualizado),
      'fecha': Timestamp.fromDate(i.fecha),
      'editadoPor': uid,
      'borrada': false,
    }).catchError((Object e) => debugPrint('No se pudo subir ${i.folio}: $e'));
  }

  /// Trae las inspecciones de la nube y las junta con las del teléfono.
  Future<void> sync() async {
    if (_auth.currentUser == null) return;
    try {
      final snap = await _col.get();
      final locales = {for (final i in inspections) i.id: i};
      for (final d in snap.docs) {
        final data = d.data();
        final remota = Inspection.fromJson({
          ...data,
          'fecha': (data['fecha'] as Timestamp).toDate().toIso8601String(),
          'actualizado': (data['actualizado'] as Timestamp).toDate().toIso8601String(),
        });
        final local = locales[d.id];
        if (data['borrada'] == true) {
          if (local != null && !local.actualizado.isAfter(remota.actualizado)) inspections.remove(local);
          locales.remove(d.id);
          continue;
        }
        if (local == null) {
          inspections.add(remota);
          _enNube[d.id] = jsonEncode(remota.toJson());
        } else if (remota.actualizado.isAfter(local.actualizado)) {
          inspections[inspections.indexOf(local)] = remota;
          _enNube[d.id] = jsonEncode(remota.toJson());
        } else {
          _enNube[d.id] = jsonEncode(remota.toJson()); // si la local es distinta, save() la sube
        }
      }
      inspections.sort((a, b) => b.fecha.compareTo(a.fecha));
      // Lo que está solo en el teléfono (o es más nuevo) se sube.
      await save();
    } catch (e) {
      debugPrint('Sincronización pendiente: $e');
    }
    await _subirFotos();
    await _bajarFotos();
  }

  /// Sube las fotos en cola, una por una. Si falla (sin señal), quedan para la próxima.
  Future<void> _subirFotos() async {
    if (_subiendo || _auth.currentUser == null) return;
    _subiendo = true;
    try {
      for (final clave in _porSubir.toList()) {
        final file = photoFile(clave.split('/').last);
        if (!await file.exists()) {
          _porSubir.remove(clave);
          continue;
        }
        try {
          await _fotosNube.child(clave).putFile(file, SettableMetadata(contentType: 'image/jpeg'));
          _porSubir.remove(clave);
          await _colaFile.writeAsString(jsonEncode(_porSubir.toList()));
        } catch (e) {
          debugPrint('Foto pendiente $clave: $e');
          break;
        }
      }
    } finally {
      _subiendo = false;
    }
  }

  /// Descarga las fotos de la nube que no están en este teléfono.
  Future<void> _bajarFotos() async {
    var nuevas = false;
    for (final i in inspections) {
      if (i.id == _ejemploId) continue;
      for (final r in i.results.values) {
        for (final f in r.fotos) {
          final file = photoFile(f);
          if (await file.exists() || _porSubir.contains('${i.id}/$f')) continue;
          try {
            await _fotosNube.child('${i.id}/$f').writeToFile(file);
            nuevas = true;
          } catch (e) {
            debugPrint('No se pudo bajar $f: $e');
            if (await file.exists()) await file.delete();
          }
        }
      }
    }
    if (nuevas) {
      PaintingBinding.instance.imageCache.clear();
      notifyListeners();
    }
  }

  String _id() => DateTime.now().microsecondsSinceEpoch.toRadixString(36) + Random().nextInt(1296).toRadixString(36);

  Inspection create() {
    final now = DateTime.now();
    final n = inspections.length + 101;
    final ymd = '${now.year % 100}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final i = Inspection(id: _id(), folio: 'ATM-$ymd-$n', fecha: now, inspector: userName);
    inspections.insert(0, i);
    return i;
  }

  Future<void> delete(Inspection i) async {
    for (final r in i.results.values) {
      for (final f in r.fotos) {
        final file = photoFile(f);
        if (await file.exists()) await file.delete();
      }
    }
    inspections.remove(i);
    _enNube.remove(i.id);
    if (i.id != _ejemploId && _auth.currentUser != null) {
      // Se marca como borrada (no se elimina) para que otros teléfonos también la quiten.
      _col.doc(i.id).set({'borrada': true, 'actualizado': Timestamp.now(), 'editadoPor': _auth.currentUser!.uid},
          SetOptions(merge: true)).catchError((Object e) => debugPrint('No se pudo borrar ${i.folio}: $e'));
    }
    await _writeLocal();
    notifyListeners();
  }

  /// Copia una foto elegida a la carpeta de la app y devuelve su nombre.
  Future<String> addPhoto(String sourcePath, Inspection i) async {
    final name = '${_id()}.jpg';
    await File(sourcePath).copy(photoFile(name).path);
    if (i.id != _ejemploId) {
      _porSubir.add('${i.id}/$name');
      await _colaFile.writeAsString(jsonEncode(_porSubir.toList()));
      unawaited(_subirFotos());
    }
    return name;
  }

  Future<void> removePhoto(ItemResult r, String name) async {
    r.fotos.remove(name);
    final f = photoFile(name);
    if (await f.exists()) await f.delete();
    await save();
  }

  Inspection _ejemplo() {
    final i = Inspection(
      id: 'ejemplo', folio: 'ATM-EJEMPLO', fecha: DateTime.now().subtract(const Duration(days: 2)),
      cliente: 'Cliente de ejemplo', telefono: '+56 9 0000 0000', marca: 'Mitsubishi', modelo: 'L200',
      anio: '2020', patente: 'LXJR-55', km: '78400', lugar: 'Coquimbo', inspector: 'Matías',
      conclusion: 'Camioneta de trabajo con uso acorde a su kilometraje. Mecánica sana. '
          'Se recomienda negociar el precio considerando el cambio de embrague.',
      recomendacion: 1,
      modalidad: 1,
    );
    for (final s in checklist) {
      for (final it in s.items) {
        i.results[it.id] = ItemResult(opt: 0);
      }
    }
    i.results['ruta.embrague'] = ItemResult(opt: 2, nota: 'Patina en tercera y cuarta bajo carga.', costo: 450000);
    i.results['motor.correas'] = ItemResult(opt: 1, nota: 'Correa de accesorios con grietas.', costo: 60000);
    i.results['baj.amort_del'] = ItemResult(opt: 1, nota: 'Humedad en amortiguador delantero derecho.', costo: 120000);
    i.results['car.visual'] = ItemResult(opt: 1, nota: 'Golpe en pisadera derecha.');
    i.results['motor.hidraulico'] = ItemResult(opt: 3);
    i.results['esc.caja'] = ItemResult(opt: 3);
    return i;
  }
}
