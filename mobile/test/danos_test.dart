import 'package:atlas_inspecciones/danos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cada tipo de vehículo arma su mapa con piezas tocables y nombradas', () {
    for (final tipo in tiposCarroceria.keys) {
      final m = mapaDe(tipo);
      final zonas = {for (final p in m.piezas) if (p.zona != null) p.zona!};
      expect(zonas, containsAll(['capo', 'parabrisas', 'techo', 'parachoques_del', 'parachoques_tras', 'puerta_del_izq', 'puerta_del_der', 'pisadera_izq', 'rueda_del_der']), reason: tipo);
      for (final z in zonas) {
        expect(m.nombres[z], isNotNull, reason: '$tipo $z');
        final c = m.centroDe(z)!;
        expect(m.zonaEn(c.x, c.y), isNotNull, reason: '$tipo $z');
      }
      // Todo el dibujo cabe en el lienzo.
      for (final p in m.piezas) {
        final (l, t, r, b) = p.forma.caja;
        expect(l >= -1 && r <= mapaAncho + 1 && t >= -1 && b <= mapaAlto + 1, isTrue, reason: '$tipo ${p.estilo}');
      }
      expect(m.piezas.length, lessThanOrEqualTo(300));
    }
  });

  test('las puertas no se montan entre sí', () {
    final m = mapaDe('sedan');
    final del = m.piezas.firstWhere((p) => p.zona == 'puerta_del_izq').forma.caja;
    final tras = m.piezas.firstWhere((p) => p.zona == 'puerta_tras_izq').forma.caja;
    expect(tras.$3, lessThanOrEqualTo(del.$1 + 6));
  });
}
