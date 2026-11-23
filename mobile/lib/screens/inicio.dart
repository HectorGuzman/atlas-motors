import 'package:flutter/material.dart';

import '../store.dart';
import '../theme.dart';
import 'garage.dart';
import 'home.dart';

/// Inicio de los admin: elegir entre Inspecciones y Garage (autos en venta).
/// El equipo Garage entra directo a Garage y no ve las inspecciones.
class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Store.I,
        builder: (context, _) {
          final s = Store.I;
          final n = s.inspections.where((i) => !i.esEjemplo).length;
          final enVenta = s.inspections.where((i) => i.venta?.publicada != null).length;
          return Scaffold(
            appBar: AppBar(
              titleSpacing: 12,
              title: Image.asset('assets/logo-wordmark.jpg', height: 44),
              centerTitle: false,
              actions: [
                IconButton(tooltip: 'Cerrar sesión', icon: const Icon(Icons.logout), onPressed: () => confirmarSalida(context)),
              ],
              bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: C.gold.withValues(alpha: .35))),
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                Text('Hola, ${s.userName}', style: display(24)),
                const SizedBox(height: 4),
                const Text('¿Qué vas a hacer hoy?', style: TextStyle(color: C.muted)),
                const SizedBox(height: 20),
                _Opcion(
                  icon: Icons.fact_check_outlined,
                  titulo: 'Inspecciones',
                  detalle: 'Inspecciones precompra, informes PDF y publicar autos.',
                  dato: n == 1 ? '1 inspección' : '$n inspecciones',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeScreen())),
                ),
                const SizedBox(height: 14),
                _Opcion(
                  icon: Icons.garage_outlined,
                  titulo: 'Garage',
                  detalle: 'Autos en venta en atlasmotors.cl: precio, fotos y videos.',
                  dato: enVenta == 0 ? null : (enVenta == 1 ? '1 en venta' : '$enVenta en venta'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GarageScreen())),
                ),
              ],
            ),
          );
        },
      );
}

class _Opcion extends StatelessWidget {
  final IconData icon;
  final String titulo, detalle;
  final String? dato;
  final VoidCallback onTap;
  const _Opcion({required this.icon, required this.titulo, required this.detalle, this.dato, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: C.green900,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [C.green800, C.green950]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: C.gold.withValues(alpha: .4)),
            ),
            child: Row(children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: C.gold.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: C.gold.withValues(alpha: .5)),
                ),
                child: Icon(icon, color: C.gold300, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(titulo, style: display(20, color: Colors.white)),
                  const SizedBox(height: 3),
                  Text(detalle, style: const TextStyle(color: Color(0xFFC7CFC9), fontSize: 13, height: 1.3)),
                  if (dato != null) ...[
                    const SizedBox(height: 8),
                    Text(dato!, style: const TextStyle(color: C.gold200, fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ]),
              ),
              const Icon(Icons.chevron_right, color: C.gold300),
            ]),
          ),
        ),
      );
}

/// La cuenta existe pero no está en el equipo (o se le quitó el acceso).
class SinAccesoScreen extends StatelessWidget {
  const SinAccesoScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.lock_outline, size: 56, color: C.gold700),
              const SizedBox(height: 14),
              Text('Tu cuenta todavía no tiene acceso', textAlign: TextAlign.center, style: display(20)),
              const SizedBox(height: 8),
              Text('Pídele a Matías o a Héctor que te agreguen al equipo. Entraste como ${Store.I.userEmail}.',
                  textAlign: TextAlign.center, style: const TextStyle(color: C.muted)),
              const SizedBox(height: 22),
              OutlinedButton(onPressed: () => Store.I.logout(), child: const Text('Cerrar sesión')),
            ]),
          ),
        ),
      );
}
