import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'agenda.dart';
import 'screens/agenda.dart';
import 'theme.dart';

/// Avisos de reservas nuevas para los admin:
///  - notificación push (la manda la función `reservar` al token guardado en
///    `equipo/{uid}.fcm`), que llega aunque la app esté cerrada;
///  - ventana emergente con la reserva cuando la app está abierta, para cada
///    reserva de la web que todavía nadie vio.
class Avisos {
  static final navigatorKey = GlobalKey<NavigatorState>();

  /// En las capturas de modo debug no hay sesión: sin avisos.
  static bool desactivados = false;
  static StreamSubscription? _nuevas;
  static final _subs = <StreamSubscription>[];
  static final _mostradas = <String>{};
  static String? _token;
  static bool _abierto = false;
  static final _cola = <Reserva>[];

  static Future<void> iniciar() async {
    if (_nuevas != null) return;
    _nuevas = Agenda.nuevas().listen((lista) {
      for (final r in lista..sort((a, b) => a.inicio.compareTo(b.inicio))) {
        if (r.origen == 'web' && _mostradas.add(r.id)) _cola.add(r);
      }
      _mostrarSiguiente();
    }, onError: (e) => debugPrint('avisos: $e'));

    final m = FirebaseMessaging.instance;
    _subs.add(FirebaseMessaging.onMessageOpenedApp.listen(_abrirDesde));
    final inicial = await m.getInitialMessage();
    if (inicial != null) WidgetsBinding.instance.addPostFrameCallback((_) => _abrirDesde(inicial));
    try {
      final permiso = await m.requestPermission(alert: true, badge: true, sound: true);
      if (permiso.authorizationStatus == AuthorizationStatus.denied) return;
      // Con la app abierta se ve la ventana emergente; la notificación solo suena.
      await m.setForegroundNotificationPresentationOptions(alert: false, badge: true, sound: true);
      // En iOS el token de Firebase necesita antes el de Apple (no existe en el simulador).
      for (var i = 0; i < 10 && await m.getAPNSToken() == null; i++) {
        await Future.delayed(const Duration(seconds: 1));
      }
      // La función envía con tokens de registro (sendEachForMulticast), por eso se usa
      // getToken y no el nuevo register(), que entrega un identificador de instalación.
      // ignore: deprecated_member_use
      final t = await m.getToken();
      if (t != null) await _guardar(t);
      // ignore: deprecated_member_use
      _subs.add(m.onTokenRefresh.listen(_guardar));
    } catch (e) {
      debugPrint('avisos: sin notificaciones push ($e)');
    }
  }

  static Future<void> _guardar(String t) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final ref = FirebaseFirestore.instance.collection('equipo').doc(uid);
    final antes = _token;
    _token = t;
    await ref.update({
      'fcm': FieldValue.arrayUnion([t]),
    });
    if (antes != null && antes != t) {
      await ref.update({
        'fcm': FieldValue.arrayRemove([antes]),
      });
    }
  }

  /// Al cerrar sesión: este teléfono deja de recibir avisos.
  static Future<void> detener() async {
    await _nuevas?.cancel();
    _nuevas = null;
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    _cola.clear();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final t = _token;
    _token = null;
    if (uid != null && t != null) {
      try {
        await FirebaseFirestore.instance.collection('equipo').doc(uid).update({
          'fcm': FieldValue.arrayRemove([t]),
        });
      } catch (_) {}
    }
  }

  static void _abrirDesde(RemoteMessage m) {
    final fecha = m.data['fecha'];
    final id = m.data['id'];
    if (id is String) {
      _mostradas.add(id);
      _cola.removeWhere((r) => r.id == id);
      Agenda.marcarVista(id).catchError((_) {});
    }
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => AgendaScreen(fecha: fecha is String ? fecha : null)),
    );
  }

  static Future<void> _mostrarSiguiente() async {
    final ctx = navigatorKey.currentContext;
    if (_abierto || _cola.isEmpty || ctx == null) return;
    final r = _cola.removeAt(0);
    _abierto = true;
    final ver = await showDialog<bool>(context: ctx, barrierDismissible: false, builder: (c) => _NuevaReserva(r));
    _abierto = false;
    Agenda.marcarVista(r.id).catchError((_) {});
    if (ver == true) {
      await navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => AgendaScreen(fecha: r.fecha)));
    }
    _mostrarSiguiente();
  }
}

class _NuevaReserva extends StatelessWidget {
  final Reserva r;
  const _NuevaReserva(this.r);

  @override
  Widget build(BuildContext context) {
    final dia = DateFormat("EEEE d 'de' MMMM", 'es').format(r.inicio);
    return AlertDialog(
      icon: const Icon(Icons.event_available, color: C.gold700, size: 36),
      title: const Text('Nueva inspección agendada', textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${dia[0].toUpperCase()}${dia.substring(1)} a las ${r.hora}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text([r.vehiculo, r.lugar].where((x) => x.isNotEmpty).join('\n'), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            '${r.nombre} · ${r.telefono}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: C.muted),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFFFF3D6), borderRadius: BorderRadius.circular(10)),
            child: Text(
              r.vence == null
                  ? 'Espera el abono.'
                  : 'Espera el abono. Si no lo confirmas, la hora se libera el ${DateFormat("d MMM 'a las' HH:mm", 'es').format(r.vence!)}.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Más tarde')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ver en la agenda')),
      ],
    );
  }
}
