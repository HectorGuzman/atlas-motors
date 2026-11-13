import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
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
  }) : results = results ?? {};

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
      );
}

/// Estado de la app. En esta versión todo se guarda en el teléfono;
/// al conectar GCP esto pasa a Firebase Auth + Firestore + Cloud Storage.
class Store extends ChangeNotifier {
  Store._();
  static final Store I = Store._();

  late Directory _dir;
  late SharedPreferences _prefs;
  List<Inspection> inspections = [];
  String? userEmail;

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
    _prefs = await SharedPreferences.getInstance();
    userEmail = _prefs.getString('email');
    if (await _file.exists()) {
      final list = jsonDecode(await _file.readAsString()) as List;
      inspections = list.map((e) => Inspection.fromJson(Map<String, dynamic>.from(e))).toList();
    } else {
      inspections = [_ejemplo()];
      await save();
    }
  }

  Future<void> login(String email) async {
    userEmail = email.trim();
    await _prefs.setString('email', userEmail!);
    notifyListeners();
  }

  Future<void> logout() async {
    userEmail = null;
    await _prefs.remove('email');
    notifyListeners();
  }

  Future<void> save() async {
    await _file.writeAsString(jsonEncode(inspections.map((i) => i.toJson()).toList()));
    notifyListeners();
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
    await save();
  }

  /// Copia una foto elegida a la carpeta de la app y devuelve su nombre.
  Future<String> addPhoto(String sourcePath) async {
    final name = '${_id()}.jpg';
    await File(sourcePath).copy(photoFile(name).path);
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
