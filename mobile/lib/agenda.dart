import 'package:cloud_firestore/cloud_firestore.dart';

/// Agenda de inspecciones. Mismo horario que la web y la función `reservar`
/// (functions/reservas/horario.js): lunes a sábado, 45 min de inspección + 45 min
/// de traslado desde las 9:00. La última hora parte a las 19:30.
const horasAgenda = ['09:00', '10:30', '12:00', '13:30', '15:00', '16:30', '18:00', '19:30'];
const diasAgenda = 60;

String fechaIso(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// El teléfono de Matías está en Chile: la hora local es la de la agenda.
DateTime inicioDe(String fecha, String hora) => DateTime.parse('${fecha}T$hora:00');

enum EstadoHora { libre, pasada, pendiente, vencida, confirmada, bloqueada }

/// Estado de una hora en `agenda/{AAAA-MM}`: e = p (pendiente de abono, vence en v),
/// c (confirmada) o b (bloqueada). r = id de la reserva.
class Celda {
  final String e;
  final int? v;
  final String? r;
  const Celda(this.e, {this.v, this.r});

  static Celda? from(Object? x) {
    if (x is! Map) return null;
    final e = x['e'];
    if (e is! String) return null;
    final v = x['v'];
    return Celda(e, v: v is num ? v.toInt() : null, r: x['r'] is String ? x['r'] as String : null);
  }
}

class Reserva {
  final String id;
  final Map<String, dynamic> d;
  Reserva(this.id, this.d);

  String s(String k) => (d[k] is String) ? d[k] as String : '';
  String get fecha => s('fecha');
  String get hora => s('hora');
  String get estado => s('estado');
  String get origen => s('origen');
  String get nombre => s('nombre');
  String get telefono => s('telefono');
  String get vehiculo => s('vehiculo');
  String get comuna => s('comuna');
  String get direccion => s('direccion');
  String get nota => s('nota');
  String get link => s('link');
  String get donde => s('donde');
  String get codigo => s('codigo');
  bool get remota => s('presente') == 'no';
  bool get vista => d['vista'] != false;
  DateTime? get vence => (d['vence'] is Timestamp) ? (d['vence'] as Timestamp).toDate() : null;
  DateTime get inicio => inicioDe(fecha, hora);
  bool get vencida => estado == 'pendiente' && vence != null && vence!.isBefore(DateTime.now());
  String get lugar => [direccion, comuna].where((x) => x.isNotEmpty).join(', ');
}

typedef Mes = Map<String, Map<String, Celda>>;

class Agenda {
  static final _db = FirebaseFirestore.instance;
  static DocumentReference<Map<String, dynamic>> _mesRef(String fecha) =>
      _db.collection('agenda').doc(fecha.substring(0, 7));
  static CollectionReference<Map<String, dynamic>> get _reservas => _db.collection('reservas');

  static Mes _leerMes(Map<String, dynamic>? data) {
    final out = <String, Map<String, Celda>>{};
    final h = data?['h'];
    if (h is Map) {
      h.forEach((fecha, horas) {
        if (fecha is String && horas is Map) {
          out[fecha] = {
            for (final e in horas.entries)
              if (e.key is String && Celda.from(e.value) != null) e.key as String: Celda.from(e.value)!,
          };
        }
      });
    }
    return out;
  }

  /// Agenda de un mes (AAAA-MM) en vivo.
  static Stream<Mes> mes(String mes) => _db.collection('agenda').doc(mes).snapshots().map((s) => _leerMes(s.data()));

  static List<Reserva> _lista(QuerySnapshot<Map<String, dynamic>> q) =>
      q.docs.map((d) => Reserva(d.id, d.data())).toList();

  static Stream<List<Reserva>> delDia(String fecha) =>
      _reservas.where('fecha', isEqualTo: fecha).snapshots().map(_lista);

  /// Reservas de la web esperando el abono (incluye las vencidas, para limpiarlas).
  static Stream<List<Reserva>> porConfirmar() => _reservas.where('estado', isEqualTo: 'pendiente').snapshots().map((q) {
    final l = _lista(q)..sort((a, b) => a.inicio.compareTo(b.inicio));
    return l;
  });

  /// Reservas de la web que todavía nadie ha visto en la app.
  static Stream<List<Reserva>> nuevas() => _reservas.where('vista', isEqualTo: false).snapshots().map(_lista);

  static Future<void> marcarVista(String id) => _reservas.doc(id).update({'vista': true});

  static FieldPath _ruta(String fecha, String hora) => FieldPath(['h', fecha, hora]);

  static bool ocupada(Celda? c) {
    if (c == null) return false;
    if (c.e == 'p') return c.v != null && c.v! > DateTime.now().millisecondsSinceEpoch;
    return c.e == 'c' || c.e == 'b';
  }

  /// Cambia una hora dentro de una transacción, para no pisar una reserva que
  /// entra desde la web al mismo tiempo. `cambio` devuelve el valor nuevo
  /// (null = dejarla libre) o lanza un error con el motivo.
  static Future<void> _cambiar(
    String fecha,
    String hora,
    Map<String, dynamic>? Function(Celda?) cambio, {
    void Function(Transaction)? ademas,
  }) {
    final ref = _mesRef(fecha);
    return _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final actual = Celda.from((snap.data()?['h'] as Map?)?[fecha]?[hora]);
      final nuevo = cambio(actual);
      if (nuevo != null) {
        tx.set(ref, {
          'h': {
            fecha: {hora: nuevo},
          },
        }, SetOptions(merge: true));
      } else if (snap.exists && actual != null) {
        tx.update(ref, {_ruta(fecha, hora): FieldValue.delete()});
      }
      ademas?.call(tx);
    });
  }

  static Future<void> bloquear(String fecha, String hora) => _cambiar(fecha, hora, (c) {
    if (ocupada(c)) throw 'Esa hora ya está tomada.';
    return {'e': 'b'};
  });

  static Future<void> desbloquear(String fecha, String hora) => _cambiar(fecha, hora, (c) {
    if (c?.e != 'b') throw 'Esa hora ya no está bloqueada.';
    return null;
  });

  /// Bloquea (o libera) todas las horas libres de un día: días que Matías no trabaja.
  /// No toca las horas con reservas. Devuelve cuántas horas cambió.
  static Future<int> bloquearDia(String fecha, {required bool bloquear}) {
    final ref = _mesRef(fecha);
    return _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final dia = (snap.data()?['h'] as Map?)?[fecha] as Map?;
      var n = 0;
      final cambios = <Object, Object>{};
      for (final h in horasAgenda) {
        final c = Celda.from(dia?[h]);
        if (bloquear && !ocupada(c)) {
          cambios[_ruta(fecha, h)] = {'e': 'b'};
          n++;
        } else if (!bloquear && c?.e == 'b') {
          cambios[_ruta(fecha, h)] = FieldValue.delete();
          n++;
        }
      }
      if (n == 0) return 0;
      if (!snap.exists) {
        tx.set(ref, {
          'h': {
            fecha: {for (final e in cambios.entries) (e.key as FieldPath).components.last: e.value},
          },
        });
      } else {
        tx.update(ref, cambios.map((k, v) => MapEntry(k, v)));
      }
      return n;
    });
  }

  /// Inspección que llegó por WhatsApp o teléfono: queda confirmada.
  static Future<void> agendarAMano(String fecha, String hora, Map<String, String> datos) {
    final ref = _reservas.doc();
    return _cambiar(
      fecha,
      hora,
      (c) {
        if (ocupada(c) && c!.e != 'b') throw 'Esa hora ya está tomada.';
        return {'e': 'c', 'r': ref.id};
      },
      ademas: (tx) => tx.set(ref, {
        ...datos,
        'fecha': fecha,
        'hora': hora,
        'estado': 'confirmada',
        'origen': 'manual',
        'vista': true,
        'creada': FieldValue.serverTimestamp(),
      }),
    );
  }

  /// Llegó el abono: la hora queda confirmada.
  static Future<void> confirmar(Reserva r) => _cambiar(r.fecha, r.hora, (c) {
    if (ocupada(c) && c!.r != r.id) throw 'Esa hora ya la tomó otra reserva.';
    return {'e': 'c', 'r': r.id};
  }, ademas: (tx) => tx.update(_reservas.doc(r.id), {'estado': 'confirmada', 'vence': null, 'vista': true}));

  /// Cancela la reserva y deja la hora libre (si sigue siendo de esta reserva).
  static Future<void> cancelar(Reserva r) => _cambiar(r.fecha, r.hora, (c) {
    if (c != null && c.r != r.id) return {'e': c.e, if (c.v != null) 'v': c.v, if (c.r != null) 'r': c.r};
    return null;
  }, ademas: (tx) => tx.update(_reservas.doc(r.id), {'estado': 'cancelada', 'vista': true}));
}
