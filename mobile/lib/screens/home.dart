import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../store.dart';
import '../theme.dart';
import 'inspection.dart';
import 'vehicle_form.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _q = '';

  Future<void> _nueva() async {
    final insp = await Navigator.push<Inspection>(
        context, MaterialPageRoute(builder: (_) => const VehicleFormScreen(), fullscreenDialog: true));
    if (insp != null && mounted) _open(insp);
  }

  void _open(Inspection i) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => InspectionScreen(inspection: i)));

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text('Tus inspecciones y fotos quedan respaldadas en la nube.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Cerrar sesión')),
        ],
      ),
    );
    if (ok == true) Store.I.logout();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: Store.I, builder: (context, _) => _build(context));

  Widget _build(BuildContext context) {
    final store = Store.I;
    final q = _q.trim().toLowerCase();
    final list = store.inspections
        .where((i) => q.isEmpty || '${i.vehiculo} ${i.cliente} ${i.patente} ${i.folio}'.toLowerCase().contains(q))
        .toList();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Image.asset('assets/logo-wordmark.jpg', height: 44),
        centerTitle: false,
        actions: [
          IconButton(tooltip: 'Cerrar sesión', icon: const Icon(Icons.logout), onPressed: _confirmLogout),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: C.gold.withValues(alpha: .35))),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: GoldButton('Nueva inspección', icon: Icons.add, onPressed: _nueva),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
        children: [
          Text('Hola, ${store.userName}', style: display(24)),
          const SizedBox(height: 4),
          Text(store.inspections.length == 1 ? '1 inspección' : '${store.inspections.length} inspecciones', style: const TextStyle(color: C.muted)),
          const SizedBox(height: 16),
          TextField(
            onChanged: (v) => setState(() => _q = v),
            decoration: const InputDecoration(
                hintText: 'Buscar por vehículo, patente o cliente', prefixIcon: Icon(Icons.search)),
          ),
          const SizedBox(height: 16),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Column(children: [
                const Icon(Icons.fact_check_outlined, size: 56, color: C.gold700),
                const SizedBox(height: 12),
                Text(q.isEmpty ? 'Aún no hay inspecciones' : 'Sin resultados para "$_q"',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 4),
                const Text('Toca "Nueva inspección" para empezar.', style: TextStyle(color: C.muted)),
              ]),
            ),
          for (final i in list) ...[_InspectionCard(i, onTap: () => _open(i)), const SizedBox(height: 12)],
        ],
      ),
    );
  }
}

class _InspectionCard extends StatelessWidget {
  final Inspection i;
  final VoidCallback onTap;
  const _InspectionCard(this.i, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    final score = i.score;
    final c = i.counts();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: C.green900,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: C.gold.withValues(alpha: .6)),
              ),
              alignment: Alignment.center,
              child: score == null
                  ? const Icon(Icons.directions_car_outlined, color: C.gold300)
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('$score', style: display(20, color: C.gold300)),
                      const Text('de 100', style: TextStyle(color: Color(0xFF9FB0A5), fontSize: 9.5)),
                    ]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(i.vehiculo.isEmpty ? 'Vehículo sin datos' : i.vehiculo,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16.5, color: C.green950)),
                const SizedBox(height: 2),
                Text(
                  [if (i.patente.isNotEmpty) i.patente, if (i.cliente.isNotEmpty) i.cliente, DateFormat('d MMM', 'es').format(i.fecha)]
                      .join(' · '),
                  style: const TextStyle(color: C.muted, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  if (i.completa)
                    const SevPill('Completa', 0)
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(color: C.cream2, borderRadius: BorderRadius.circular(8)),
                      child: Text(i.respondidos == 0 ? 'Pendiente' : 'En curso · ${i.respondidos} puntos',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: C.green900)),
                    ),
                  if (c[1] > 0) SevPill('${c[1]} obs.', 1),
                  if (c[2] > 0) SevPill('${c[2]} problema${c[2] == 1 ? '' : 's'}', 2),
                ]),
              ]),
            ),
            const Icon(Icons.chevron_right, color: C.muted),
          ]),
        ),
      ),
    );
  }
}
