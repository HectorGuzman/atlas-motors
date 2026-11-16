import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'checklist.dart';
import 'marketplace.dart';

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

const combustibles = ['Bencina', 'Diésel', 'Híbrido', 'Eléctrico'];
const transmisiones = ['Manual', 'Automática'];

/// Datos para vender el auto en el marketplace de atlasmotors.cl.
/// Solo se usa cuando el dueño del auto pidió la inspección para venderlo.
class Venta {
  int? precio;
  String comuna, combustible, transmision, descripcion, comentario;
  List<String> fotos; // fotos elegidas para la publicación, en orden (la primera es la portada)
  bool autorizada; // el dueño autorizó publicar
  DateTime? publicada; // null si no está en la web

  Venta({
    this.precio,
    this.comuna = '',
    this.combustible = '',
    this.transmision = '',
    this.descripcion = '',
    this.comentario = '',
    List<String>? fotos,
    this.autorizada = false,
    this.publicada,
  }) : fotos = fotos ?? [];

  Map<String, dynamic> toJson() => {
        'precio': precio, 'comuna': comuna, 'combustible': combustible, 'transmision': transmision,
        'descripcion': descripcion, 'comentario': comentario, 'fotos': fotos, 'autorizada': autorizada,
        'publicada': publicada?.toIso8601String(),
      };

  factory Venta.fromJson(Map<String, dynamic> j) => Venta(
        precio: j['precio'], comuna: j['comuna'] ?? '', combustible: j['combustible'] ?? '',
        transmision: j['transmision'] ?? '', descripcion: j['descripcion'] ?? '', comentario: j['comentario'] ?? '',
        fotos: List<String>.from(j['fotos'] ?? []), autorizada: j['autorizada'] ?? false,
        publicada: j['publicada'] == null ? null : DateTime.parse(j['publicada']),
      );
}

class Inspection {
  String id, folio;
  DateTime fecha;
  String cliente, telefono, marca, modelo, anio, patente, km, lugar, inspector;
  String conclusion;
  int? recomendacion;
  int modalidad; // índice en [modalidades]
  Map<String, ItemResult> results;
  Venta? venta; // solo si el auto se va a vender en atlasmotors.cl
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
    this.venta,
    DateTime? actualizado,
  })  : results = results ?? {},
        actualizado = actualizado ?? fecha;

  /// La inspección de ejemplo que trae la app (no se respalda ni se publica).
  bool get esEjemplo => id == 'ejemplo';

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
        if (venta != null) 'venta': venta!.toJson(),
      };

  /// Todas las fotos de la inspección: las de cada punto y las tomadas para la venta.
  Iterable<String> get todasLasFotos => {...results.values.expand((r) => r.fotos), ...?venta?.fotos};

  factory Inspection.fromJson(Map<String, dynamic> j) => Inspection(
        id: j['id'], folio: j['folio'], fecha: DateTime.parse(j['fecha']),
        cliente: j['cliente'] ?? '', telefono: j['telefono'] ?? '', marca: j['marca'] ?? '',
        modelo: j['modelo'] ?? '', anio: j['anio'] ?? '', patente: j['patente'] ?? '', km: j['km'] ?? '',
        lugar: j['lugar'] ?? '', inspector: j['inspector'] ?? '', conclusion: j['conclusion'] ?? '',
        recomendacion: j['recomendacion'],
        modalidad: j['modalidad'] ?? 0,
        results: (j['results'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, ItemResult.fromJson(Map<String, dynamic>.from(v)))),
        venta: j['venta'] == null ? null : Venta.fromJson(Map<String, dynamic>.from(j['venta'])),
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
class Store extends ChangeNotifier with WidgetsBindingObserver {
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

  /// Versión reducida de la foto para el PDF (se crea la primera vez que se usa).
  File photoPdfFile(String name) => File('${_dir.path}/fotos-pdf/$name');

  /// Fotos de la inspección que todavía no están en este teléfono.
  int fotosFaltantes(Inspection i) =>
      i.todasLasFotos.where((f) => !photoFile(f).existsSync()).length;

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
    WidgetsBinding.instance.addObserver(this);
    if (userEmail != null) unawaited(sync());
  }

  /// Fotos tomadas en este teléfono que todavía no llegan a la nube.
  int get fotosPorSubir => _porSubir.length;

  DateTime? _ultimaSync;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      unawaited(guardarPendiente()); // que no se pierda lo que estaba escribiendo
    } else if (state == AppLifecycleState.resumed && userEmail != null) {
      // Al volver a la app: trae cambios y reintenta fotos (máximo una vez por minuto).
      final u = _ultimaSync;
      if (u == null || DateTime.now().difference(u) > const Duration(minutes: 1)) unawaited(sync());
    }
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
  ///
  /// Con [solo] revisa únicamente esa inspección (lo normal al editar);
  /// sin él revisa todas (al sincronizar).
  Future<void> save([Inspection? solo]) async {
    // Si este guardado incluye lo que se estaba escribiendo, ya no hace falta esperar.
    if (solo == null || solo == _pendiente) {
      _escribiendo?.cancel();
      _escribiendo = null;
      _pendiente = null;
    }
    final now = DateTime.now();
    for (final i in solo == null ? inspections : [solo]) {
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

  /// Para campos de texto: guarda cuando deja de escribir un momento, no en cada tecla.
  Timer? _escribiendo;
  Inspection? _pendiente;
  void guardarAlEscribir(Inspection i) {
    if (_pendiente != null && _pendiente != i) save(_pendiente);
    _pendiente = i;
    _escribiendo?.cancel();
    _escribiendo = Timer(const Duration(milliseconds: 800), () {
      _pendiente = null;
      save(i);
    });
  }

  /// Guarda de inmediato lo que esté esperando (al salir de la app o de una pantalla).
  Future<void> guardarPendiente() async {
    final p = _pendiente;
    _pendiente = null;
    if (p != null) await save(p);
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
    _ultimaSync = DateTime.now();
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
          notifyListeners();
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
      for (final f in i.todasLasFotos) {
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
    if (i.venta?.publicada != null) {
      try {
        await Marketplace.despublicar(i);
      } catch (e) {
        debugPrint('No se pudo quitar la publicación de ${i.folio}: $e');
      }
    }
    for (final f in i.todasLasFotos) {
      await _borrarFotoLocal(f);
      _porSubir.remove('${i.id}/$f');
    }
    await _colaFile.writeAsString(jsonEncode(_porSubir.toList()));
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

  Future<void> removePhoto(Inspection i, ItemResult r, String name) async {
    r.fotos.remove(name);
    i.venta?.fotos.remove(name);
    await _borrarFotoLocal(name);
    if (_porSubir.remove('${i.id}/$name')) await _colaFile.writeAsString(jsonEncode(_porSubir.toList()));
    await save(i);
  }

  /// Quita una foto de la publicación. Si era una foto tomada solo para la
  /// venta (no está en ningún punto del checklist), se borra del teléfono.
  Future<void> quitarFotoVenta(Inspection i, String name) async {
    i.venta?.fotos.remove(name);
    if (!i.results.values.any((r) => r.fotos.contains(name))) {
      await _borrarFotoLocal(name);
      if (_porSubir.remove('${i.id}/$name')) await _colaFile.writeAsString(jsonEncode(_porSubir.toList()));
    }
    await save(i);
  }

  Future<void> _borrarFotoLocal(String name) async {
    for (final f in [photoFile(name), photoPdfFile(name)]) {
      if (await f.exists()) await f.delete();
    }
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
