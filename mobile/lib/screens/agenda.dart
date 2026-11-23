import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../agenda.dart';
import '../theme.dart';

/// Agenda de inspecciones (solo admin): las horas de cada día, las reservas que
/// llegan desde atlasmotors.cl y las que se agendan a mano. Desde aquí se
/// confirma el abono, se cancela y se bloquean horas.
class AgendaScreen extends StatefulWidget {
  final String? fecha;

  /// Datos de ejemplo, sin Firestore (solo para capturas en modo debug).
  final bool demo;
  const AgendaScreen({super.key, this.fecha, this.demo = false});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  late final List<DateTime> _dias;
  late String _fecha;
  final _meses = <String, Mes>{};
  final _subs = <StreamSubscription>[];
  StreamSubscription? _subDia;
  List<Reserva> _delDia = [];
  List<Reserva> _porConfirmar = [];
  final _tira = ScrollController();

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    final base = DateTime(hoy.year, hoy.month, hoy.day);
    _dias = [
      for (var i = 0; i <= diasAgenda; i++)
        if (base.add(Duration(days: i)).weekday != DateTime.sunday) base.add(Duration(days: i)),
    ];
    _fecha = widget.fecha ?? fechaIso(_dias.first);
    if (widget.demo) {
      _cargarDemo();
      return;
    }
    final meses = {for (final d in _dias) fechaIso(d).substring(0, 7)};
    for (final m in meses) {
      _subs.add(Agenda.mes(m).listen((v) => setState(() => _meses[m] = v)));
    }
    _subs.add(Agenda.porConfirmar().listen((v) => setState(() => _porConfirmar = v)));
    _escucharDia();
    WidgetsBinding.instance.addPostFrameCallback((_) => _centrarDia());
  }

  void _escucharDia() {
    _subDia?.cancel();
    _subDia = Agenda.delDia(_fecha).listen((v) => setState(() => _delDia = v));
  }

  void _centrarDia() {
    final i = _dias.indexWhere((d) => fechaIso(d) == _fecha);
    if (i > 0 && _tira.hasClients) _tira.jumpTo((i * 64.0 - 120).clamp(0, _tira.position.maxScrollExtent));
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _subDia?.cancel();
    _tira.dispose();
    super.dispose();
  }

  void _elegir(String f) {
    if (f == _fecha) return;
    setState(() {
      _fecha = f;
      _delDia = widget.demo ? _demoDia(f) : [];
    });
    if (!widget.demo) _escucharDia();
  }

  Celda? _celda(String f, String h) => _meses[f.substring(0, 7)]?[f]?[h];

  Reserva? _reservaDe(String h) {
    final c = _celda(_fecha, h);
    final activas = _delDia.where((r) => r.hora == h && r.estado != 'cancelada').toList();
    if (c?.r != null) {
      for (final r in activas) {
        if (r.id == c!.r) return r;
      }
    }
    return activas.isEmpty ? null : activas.first;
  }

  EstadoHora _estado(String h) {
    final c = _celda(_fecha, h);
    final r = _reservaDe(h);
    if (c?.e == 'b') return EstadoHora.bloqueada;
    if (c?.e == 'c' || r?.estado == 'confirmada') return EstadoHora.confirmada;
    if (r != null && r.estado == 'pendiente') return r.vencida ? EstadoHora.vencida : EstadoHora.pendiente;
    if (c?.e == 'p' && Agenda.ocupada(c)) return EstadoHora.pendiente;
    if (inicioDe(_fecha, h).isBefore(DateTime.now())) return EstadoHora.pasada;
    return EstadoHora.libre;
  }

  int _tomadas(String f) => horasAgenda.where((h) => Agenda.ocupada(_celda(f, h))).length;

  Future<void> _hacer(Future<void> Function() accion, String ok) async {
    if (widget.demo) return;
    try {
      await accion();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok)));
    } catch (e) {
      if (mounted) {
        final msg = e is String ? e : 'No se pudo guardar. Revisa la conexión e intenta de nuevo.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: C.bad));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vigentes = _porConfirmar.where((r) => !r.vencida).toList();
    final vencidas = _porConfirmar.where((r) => r.vencida).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda')),
      body: Column(
        children: [
          _tiraDias(),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
              children: [
                if (vigentes.isNotEmpty || vencidas.isNotEmpty) ...[
                  _porConfirmarCard(vigentes, vencidas),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    Expanded(child: Text(_tituloDia(), style: display(19))),
                    _botonDia(),
                  ],
                ),
                const SizedBox(height: 10),
                for (final h in horasAgenda) _horaTile(h),
                const SizedBox(height: 12),
                const Text(
                  'Cada hora es una inspección de 45 minutos más 45 de traslado. Las reservas de la web quedan '
                  'pendientes de abono por 1 hora: si no confirmas el abono, la reserva se cancela y la hora se libera sola.',
                  style: TextStyle(color: C.muted, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Bloquear el día entero (no trabaja) o volver a abrirlo.
  Widget _botonDia() {
    final libres = horasAgenda.where((h) => _estado(h) == EstadoHora.libre).length;
    final bloqueadas = horasAgenda.where((h) => _estado(h) == EstadoHora.bloqueada).length;
    if (libres == 0 && bloqueadas == 0) return const SizedBox.shrink();
    final bloquear = libres > 0;
    return TextButton.icon(
      onPressed: () async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text(bloquear ? '¿Bloquear el día?' : '¿Abrir el día?'),
            content: Text(
              bloquear
                  ? 'Se bloquean las $libres horas libres del ${_tituloDia().toLowerCase()}. Las reservas que ya hay no se tocan.'
                  : 'Las $bloqueadas horas bloqueadas vuelven a quedar libres para reservar en la web.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('No')),
              FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(bloquear ? 'Bloquear' : 'Abrir')),
            ],
          ),
        );
        if (ok == true) {
          await _hacer(
            () => Agenda.bloquearDia(_fecha, bloquear: bloquear),
            bloquear ? 'Día bloqueado' : 'Día abierto',
          );
        }
      },
      icon: Icon(bloquear ? Icons.block : Icons.lock_open, size: 18),
      label: Text(bloquear ? 'Bloquear día' : 'Abrir día'),
    );
  }

  String _tituloDia() {
    final d = DateTime.parse(_fecha);
    final t = DateFormat("EEEE d 'de' MMMM", 'es').format(d);
    return t[0].toUpperCase() + t.substring(1);
  }

  Widget _tiraDias() => SizedBox(
    height: 84,
    child: ListView.builder(
      controller: _tira,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      itemCount: _dias.length,
      itemBuilder: (_, i) {
        final d = _dias[i];
        final f = fechaIso(d);
        final on = f == _fecha;
        final n = _tomadas(f);
        final lleno = n == horasAgenda.length;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _elegir(f),
            child: Container(
              width: 58,
              decoration: BoxDecoration(
                color: on ? C.green900 : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: on ? C.green900 : C.line),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE', 'es').format(d).replaceAll('.', ''),
                    style: TextStyle(fontSize: 12, color: on ? C.gold200 : C.muted),
                  ),
                  Text(
                    '${d.day}',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: on ? Colors.white : C.text),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    height: 6,
                    width: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: n == 0 ? Colors.transparent : (lleno ? C.bad : (on ? C.gold300 : C.gold700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget _porConfirmarCard(List<Reserva> vigentes, List<Reserva> vencidas) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7E0),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: C.warn.withValues(alpha: .45)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.hourglass_top_rounded, color: C.warn, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                vigentes.isEmpty
                    ? 'Reservas vencidas sin abono'
                    : (vigentes.length == 1
                          ? '1 reserva espera el abono'
                          : '${vigentes.length} reservas esperan el abono'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        for (final r in [...vigentes, ...vencidas])
          InkWell(
            onTap: () {
              _elegir(r.fecha);
              WidgetsBinding.instance.addPostFrameCallback((_) => _centrarDia());
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${DateFormat('EEE d MMM', 'es').format(r.inicio)} · ${r.hora} · ${r.vehiculo}',
                      style: TextStyle(color: r.vencida ? C.muted : C.text, fontSize: 13.5),
                    ),
                  ),
                  Text(
                    r.vencida ? 'Venció' : 'Vence ${DateFormat('HH:mm').format(r.vence ?? r.inicio)}',
                    style: TextStyle(fontSize: 12, color: r.vencida ? C.bad : C.warn, fontWeight: FontWeight.w700),
                  ),
                  const Icon(Icons.chevron_right, size: 18, color: C.muted),
                ],
              ),
            ),
          ),
      ],
    ),
  );

  static const _colores = {
    EstadoHora.libre: (C.ok, Color(0xFFE3F4EA), 'Libre'),
    EstadoHora.pasada: (C.muted, Color(0xFFF0EEE8), 'Pasó'),
    EstadoHora.pendiente: (C.warn, Color(0xFFFFF3D6), 'Espera abono'),
    EstadoHora.vencida: (C.bad, Color(0xFFFDE4E1), 'Venció sin abono'),
    EstadoHora.confirmada: (C.green800, Color(0xFFDDEBE2), 'Confirmada'),
    EstadoHora.bloqueada: (C.muted, Color(0xFFE9E6DD), 'Bloqueada'),
  };

  Widget _horaTile(String h) {
    final est = _estado(h);
    final r = _reservaDe(h);
    final (color, fondo, etiqueta) = _colores[est]!;
    final fin = inicioDe(_fecha, h).add(const Duration(minutes: 45));
    final detalle = r != null
        ? [r.vehiculo, r.comuna, r.nombre].where((x) => x.isNotEmpty).join(' · ')
        : (est == EstadoHora.bloqueada ? 'No se puede reservar en la web' : null);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: est == EstadoHora.pasada && r == null ? null : () => _acciones(h, est, r),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: C.line),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 62,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      Text(
                        'a ${DateFormat('HH:mm').format(fin)}',
                        style: const TextStyle(fontSize: 11.5, color: C.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(99)),
                        child: Text(
                          etiqueta,
                          style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                      ),
                      if (detalle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          detalle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13.5),
                        ),
                      ],
                      if (r != null && r.origen == 'web' && est != EstadoHora.confirmada)
                        const Text('Reservada en la web', style: TextStyle(fontSize: 11.5, color: C.muted)),
                    ],
                  ),
                ),
                if (!(est == EstadoHora.pasada && r == null)) const Icon(Icons.more_horiz, color: C.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _acciones(String h, EstadoHora est, Reserva? r) async {
    final titulo = '${_tituloDia()} · $h';
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        void cerrarY(VoidCallback f) {
          Navigator.pop(ctx);
          f();
        }

        final acciones = <Widget>[
          if (est == EstadoHora.libre) ...[
            ListTile(
              leading: const Icon(Icons.edit_calendar_outlined),
              title: const Text('Agendar a mano'),
              subtitle: const Text('Una inspección que te pidieron por WhatsApp o teléfono'),
              onTap: () => cerrarY(() => _agendarAMano(h)),
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Bloquear hora'),
              subtitle: const Text('Nadie podrá reservarla en la web'),
              onTap: () => cerrarY(() => _hacer(() => Agenda.bloquear(_fecha, h), 'Hora bloqueada')),
            ),
          ],
          if (est == EstadoHora.bloqueada) ...[
            ListTile(
              leading: const Icon(Icons.lock_open),
              title: const Text('Desbloquear'),
              subtitle: const Text('Vuelve a quedar libre en la web'),
              onTap: () => cerrarY(() => _hacer(() => Agenda.desbloquear(_fecha, h), 'Hora libre otra vez')),
            ),
            ListTile(
              leading: const Icon(Icons.edit_calendar_outlined),
              title: const Text('Agendar a mano'),
              onTap: () => cerrarY(() => _agendarAMano(h)),
            ),
          ],
          if (r != null && (est == EstadoHora.pendiente || est == EstadoHora.vencida))
            ListTile(
              leading: const Icon(Icons.verified_outlined, color: C.ok),
              title: Text(est == EstadoHora.vencida ? 'Confirmar igual (llegó el abono)' : 'Llegó el abono: confirmar'),
              onTap: () => cerrarY(() => _hacer(() => Agenda.confirmar(r), 'Inspección confirmada')),
            ),
          if (r != null && r.telefono.isNotEmpty) ...[
            ListTile(
              leading: const Icon(Icons.chat_outlined),
              title: const Text('Escribir por WhatsApp'),
              subtitle: Text(r.telefono),
              onTap: () => cerrarY(() => _abrir(_whatsapp(r))),
            ),
            ListTile(
              leading: const Icon(Icons.call_outlined),
              title: const Text('Llamar'),
              onTap: () =>
                  cerrarY(() => _abrir(Uri(scheme: 'tel', path: r.telefono.replaceAll(RegExp(r'[^\d+]'), '')))),
            ),
          ],
          if (r != null && r.estado != 'cancelada')
            ListTile(
              leading: const Icon(Icons.event_busy_outlined, color: C.bad),
              title: Text(
                est == EstadoHora.vencida ? 'Liberar la hora' : 'Cancelar reserva',
                style: const TextStyle(color: C.bad),
              ),
              onTap: () => cerrarY(() => _confirmarCancelar(r)),
            ),
        ];
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: display(18)),
                if (r != null) ...[const SizedBox(height: 10), _detalle(r, est)],
                const SizedBox(height: 6),
                ...acciones,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detalle(Reserva r, EstadoHora est) {
    Widget fila(String k, String v) => v.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 92,
                  child: Text(k, style: const TextStyle(color: C.muted, fontSize: 13)),
                ),
                Expanded(child: SelectableText(v, style: const TextStyle(fontSize: 14))),
              ],
            ),
          );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: C.cream, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          fila('Vehículo', r.vehiculo),
          fila('Lugar', r.lugar),
          fila('Modalidad', r.remota ? 'Remota (no estará presente)' : 'Presencial'),
          fila('Vendedor', r.donde),
          fila('Cliente', r.nombre),
          fila('Teléfono', r.telefono),
          fila('Publicación', r.link),
          fila('Comentarios', r.nota),
          fila('Código', r.codigo),
          if (est == EstadoHora.pendiente && r.vence != null)
            fila(
              'Abono',
              'Se libera el ${DateFormat("d MMM 'a las' HH:mm", 'es').format(r.vence!)} si no lo confirmas',
            ),
          fila('Origen', r.origen == 'web' ? 'Reservada en atlasmotors.cl' : 'Agendada a mano'),
        ],
      ),
    );
  }

  Uri _whatsapp(Reserva r) {
    var n = r.telefono.replaceAll(RegExp(r'\D'), '');
    if (n.length == 9 && n.startsWith('9')) n = '56$n';
    final texto =
        'Hola ${r.nombre.split(' ').first}, te escribo de Atlas Motors por tu inspección del '
        '${DateFormat("EEEE d 'de' MMMM", 'es').format(r.inicio)} a las ${r.hora} (${r.vehiculo}).';
    return Uri.parse('https://wa.me/$n?text=${Uri.encodeComponent(texto)}');
  }

  Future<void> _abrir(Uri u) async {
    if (!await launchUrl(u, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir')));
    }
  }

  Future<void> _confirmarCancelar(Reserva r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(r.vencida ? '¿Liberar la hora?' : '¿Cancelar la reserva?'),
        content: Text(
          '${r.vehiculo} · ${r.nombre}\nLa hora de las ${r.hora} queda libre para reservar en la web. '
          'Avísale al cliente si corresponde.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(r.vencida ? 'Liberar' : 'Cancelar reserva', style: const TextStyle(color: C.bad)),
          ),
        ],
      ),
    );
    if (ok == true) await _hacer(() => Agenda.cancelar(r), 'Hora liberada');
  }

  Future<void> _agendarAMano(String h) async {
    final datos = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(builder: (_) => _AgendarAManoScreen(titulo: '${_tituloDia()} · $h')),
    );
    if (datos != null) await _hacer(() => Agenda.agendarAMano(_fecha, h, datos), 'Inspección agendada');
  }

  // ----------------- datos de ejemplo para capturas -----------------
  void _cargarDemo() {
    final f0 = fechaIso(_dias.first);
    _meses[f0.substring(0, 7)] = {
      f0: {
        '10:30': const Celda('c', r: 'a'),
        '13:30': Celda('p', v: DateTime.now().add(const Duration(hours: 9)).millisecondsSinceEpoch, r: 'b'),
        '18:00': const Celda('b'),
      },
    };
    if (_dias.length > 2) {
      final f2 = fechaIso(_dias[2]);
      _meses.putIfAbsent(f2.substring(0, 7), () => {})[f2] = {for (final h in horasAgenda) h: const Celda('b')};
    }
    _delDia = _demoDia(f0);
    _porConfirmar = _delDia.where((r) => r.estado == 'pendiente').toList();
  }

  List<Reserva> _demoDia(String f) {
    if (f != fechaIso(_dias.first)) return [];
    return [
      Reserva('a', {
        'fecha': f,
        'hora': '10:30',
        'estado': 'confirmada',
        'origen': 'manual',
        'vehiculo': 'Toyota Hilux 2021',
        'comuna': 'La Serena',
        'nombre': 'Cliente de ejemplo',
        'telefono': '+56 9 0000 0000',
      }),
      Reserva('b', {
        'fecha': f,
        'hora': '13:30',
        'estado': 'pendiente',
        'origen': 'web',
        'vehiculo': 'Mazda CX-5 2019',
        'comuna': 'Coquimbo',
        'nombre': 'Cliente web',
        'telefono': '+56 9 1111 1111',
        'codigo': 'K7M2Q',
      }),
    ];
  }
}

class _AgendarAManoScreen extends StatefulWidget {
  final String titulo;
  const _AgendarAManoScreen({required this.titulo});

  @override
  State<_AgendarAManoScreen> createState() => _AgendarAManoScreenState();
}

class _AgendarAManoScreenState extends State<_AgendarAManoScreen> {
  final _c = {
    for (final k in ['nombre', 'telefono', 'vehiculo', 'comuna', 'direccion', 'nota']) k: TextEditingController(),
  };
  bool _remota = false;

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _campo(String k, String label, {TextInputType? tipo, int lineas = 1, String? ayuda}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: _c[k],
      keyboardType: tipo,
      maxLines: lineas,
      textCapitalization: tipo == null ? TextCapitalization.sentences : TextCapitalization.none,
      decoration: InputDecoration(labelText: label, helperText: ayuda),
      onChanged: (_) => setState(() {}),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final listo = _c['vehiculo']!.text.trim().isNotEmpty || _c['nombre']!.text.trim().isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Agendar a mano')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(widget.titulo, style: display(18)),
          const SizedBox(height: 4),
          const Text('Queda confirmada y la hora se ocupa en la web.', style: TextStyle(color: C.muted)),
          const SizedBox(height: 16),
          _campo('vehiculo', 'Vehículo', ayuda: 'Marca, modelo y año'),
          _campo('nombre', 'Nombre del cliente'),
          _campo('telefono', 'Teléfono', tipo: TextInputType.phone),
          _campo('comuna', 'Comuna'),
          _campo('direccion', 'Dirección'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Inspección remota'),
            subtitle: const Text('El cliente no estará presente'),
            value: _remota,
            onChanged: (v) => setState(() => _remota = v),
          ),
          _campo('nota', 'Comentarios', lineas: 3),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: listo
                ? () => Navigator.pop(context, {
                    for (final e in _c.entries) e.key: e.value.text.trim(),
                    'presente': _remota ? 'no' : 'si',
                  })
                : null,
            icon: const Icon(Icons.check),
            label: const Text('Agendar'),
          ),
        ],
      ),
    );
  }
}
