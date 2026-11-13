import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../checklist.dart';
import '../messages.dart';
import '../store.dart';
import '../theme.dart';
import 'report.dart';
import 'section.dart';
import 'vehicle_form.dart';

/// Resumen de una inspección: datos, avance por sección, conclusión e informe.
class InspectionScreen extends StatefulWidget {
  final Inspection inspection;
  const InspectionScreen({super.key, required this.inspection});
  @override
  State<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends State<InspectionScreen> {
  Inspection get i => widget.inspection;
  late final _conclusion = TextEditingController(text: i.conclusion);

  @override
  void dispose() {
    _conclusion.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('¿Eliminar inspección?'),
        content: Text('Se borrará ${i.vehiculo.isEmpty ? 'esta inspección' : 'la inspección de ${i.vehiculo}'} con sus fotos. No se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: C.bad),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true) {
      await Store.I.delete(i);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _go(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final score = i.score;
    final c = i.counts();
    final km = int.tryParse(i.km);
    return Scaffold(
      appBar: AppBar(
        title: Text(i.folio),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => v == 'edit' ? _go(VehicleFormScreen(inspection: i)) : _delete(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Editar datos')),
              PopupMenuItem(value: 'delete', child: Text('Eliminar inspección')),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: GoldButton('Ver informe PDF',
              icon: Icons.picture_as_pdf_outlined,
              onPressed: i.respondidos == 0 ? null : () => _go(ReportScreen(inspection: i))),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [C.green800, C.green950]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: C.gold.withValues(alpha: .4)),
            ),
            child: Row(children: [
              SizedBox(
                width: 76,
                height: 76,
                child: Stack(alignment: Alignment.center, children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: (score ?? 0) / 100,
                      strokeWidth: 7,
                      backgroundColor: Colors.white.withValues(alpha: .12),
                      color: C.gold,
                    ),
                  ),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(score?.toString() ?? '–', style: display(24, color: C.gold300)),
                    const Text('de 100', style: TextStyle(color: Color(0xFF9FB0A5), fontSize: 10)),
                  ]),
                ]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(i.vehiculo, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(
                    [
                      if (i.patente.isNotEmpty) i.patente,
                      if (km != null) '${NumberFormat.decimalPattern('es').format(km)} km',
                      DateFormat('d MMM y', 'es').format(i.fecha),
                    ].join(' · '),
                    style: const TextStyle(color: Color(0xFFC7CFC9), fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  if (i.modalidad == 1) ...[
                    const Row(children: [
                      Icon(Icons.videocam_outlined, size: 16, color: C.gold300),
                      SizedBox(width: 5),
                      Text('Inspección remota', style: TextStyle(color: C.gold300, fontSize: 12.5, fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 4),
                  ],
                  Text('${i.respondidos} de $totalItems puntos revisados',
                      style: const TextStyle(color: C.gold200, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, children: [
                    SevPill('${c[0]} bien', 0),
                    SevPill('${c[1]} obs.', 1),
                    SevPill('${c[2]} mal', 2),
                  ]),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 22),
          Text('Checklist', style: display(18)),
          const SizedBox(height: 10),
          for (final s in checklist) ...[_SectionTile(i, s, onTap: () => _go(SectionScreen(inspection: i, section: s))), const SizedBox(height: 10)],
          const SizedBox(height: 14),
          _Hallazgos(i),
          const SizedBox(height: 22),
          Text('Conclusión', style: display(18)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (var r = 0; r < recomendaciones.length; r++)
              ChoiceChip(
                label: Text(recomendaciones[r]),
                selected: i.recomendacion == r,
                showCheckmark: false,
                selectedColor: C.sev[r],
                backgroundColor: Colors.white,
                side: BorderSide(color: i.recomendacion == r ? C.sev[r] : C.line),
                labelStyle: TextStyle(
                    fontWeight: FontWeight.w600, color: i.recomendacion == r ? Colors.white : C.text),
                onSelected: (sel) {
                  setState(() => i.recomendacion = sel ? r : null);
                  Store.I.save();
                },
              ),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: _conclusion,
            minLines: 3,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Resumen para el cliente: estado general y qué considerar al negociar.'),
            onChanged: (v) {
              i.conclusion = v;
              Store.I.save();
            },
          ),
        ],
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  final Inspection i;
  final Section s;
  final VoidCallback onTap;
  const _SectionTile(this.i, this.s, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    final done = i.answeredIn(s);
    final c = i.counts(s);
    final full = done == s.items.length;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: full ? C.green900 : C.cream2, borderRadius: BorderRadius.circular(13)),
              child: Icon(full ? Icons.check : s.icon, color: full ? C.gold300 : C.green700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${checklist.indexOf(s) + 1}. ${s.title}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                      value: done / s.items.length, minHeight: 5, backgroundColor: C.cream2, color: C.gold),
                ),
              ]),
            ),
            const SizedBox(width: 12),
            if (c[2] > 0) ...[SevPill('${c[2]}', 2), const SizedBox(width: 4)],
            if (c[1] > 0) ...[SevPill('${c[1]}', 1), const SizedBox(width: 4)],
            Text('$done/${s.items.length}', style: const TextStyle(color: C.muted, fontWeight: FontWeight.w600)),
            const Icon(Icons.chevron_right, color: C.muted),
          ]),
        ),
      ),
    );
  }
}

/// Resumen de hallazgos con costo estimado y botón para mandarlo por WhatsApp.
class _Hallazgos extends StatelessWidget {
  final Inspection i;
  const _Hallazgos(this.i);

  @override
  Widget build(BuildContext context) {
    final hs = i.hallazgos;
    final total = i.costoTotal;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Hallazgos', style: display(18)),
            const Spacer(),
            if (hs.isNotEmpty) Text('${hs.length}', style: const TextStyle(fontWeight: FontWeight.w700, color: C.muted)),
          ]),
          const SizedBox(height: 8),
          if (hs.isEmpty)
            const Text('Sin observaciones por ahora.', style: TextStyle(color: C.muted))
          else
            for (final h in hs.take(6))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  SevPill(h.opt.label, h.opt.sev),
                  const SizedBox(width: 8),
                  Expanded(child: Text(h.item.label, style: const TextStyle(fontSize: 14))),
                  if (h.result.costo != null)
                    Text(clp(h.result.costo!), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                ]),
              ),
          if (hs.length > 6) Text('y ${hs.length - 6} más', style: const TextStyle(color: C.muted, fontSize: 13)),
          if (total != null) ...[
            const Divider(height: 22),
            Row(children: [
              const Expanded(child: Text('Reparaciones estimadas', style: TextStyle(fontWeight: FontWeight.w700))),
              Text(clp(total), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: C.green900)),
            ]),
          ],
          const SizedBox(height: 12),
          Builder(
            builder: (bc) => OutlinedButton.icon(
              onPressed: i.respondidos == 0 ? null : () => compartir(bc, mensajeResumen(i)),
              icon: const Icon(Icons.send_outlined),
              label: const Text('Enviar resumen al cliente'),
              style: OutlinedButton.styleFrom(
                foregroundColor: C.green900,
                side: const BorderSide(color: C.green700, width: 1.5),
                minimumSize: const Size.fromHeight(46),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
