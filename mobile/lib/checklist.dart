import 'package:flutter/material.dart';

/// Checklist en el orden en que Matías recorre el vehículo:
/// carrocería 360° → estructura y chasis → motor → parte baja →
/// interior → escáner → prueba de ruta → documentos.
///
/// Cuando conectemos GCP vivirá en Firestore, para editarlo sin publicar
/// una versión nueva de la app.

/// Gravedad de una respuesta: 0 = bien, 1 = observación, 2 = problema,
/// -1 = no aplica (no cuenta para el puntaje).
class Opt {
  final String label;
  final int sev;
  const Opt(this.label, this.sev);
}

class Item {
  final String id;
  final String label;
  final List<Opt> opts;
  final String? ayuda; // qué mirar, en una línea
  const Item(this.id, this.label, this.opts, {this.ayuda});
}

class Section {
  final String id;
  final String title;
  final String resumen;
  final IconData icon;
  final List<Item> items;
  const Section(this.id, this.title, this.resumen, this.icon, this.items);
}

const noAplica = Opt('No aplica', -1);

const estado = [Opt('Bueno', 0), Opt('Regular', 1), Opt('Malo', 2)];
const cambio = [Opt('Bueno', 0), Opt('Para cambio', 1), Opt('Malo', 2)];
const nivel = [Opt('Normal', 0), Opt('Medio', 1), Opt('Bajo', 2)];
const fugas = [Opt('Sin fugas', 0), Opt('Humedad leve', 1), Opt('Con fuga', 2)];
const ruido = [Opt('Sin ruidos', 0), Opt('Ruido leve', 1), Opt('Ruido anormal', 2)];
const funciona = [Opt('Funciona', 0), Opt('Con detalle', 1), Opt('No funciona', 2)];
const docs = [Opt('Al día', 0), Opt('Por vencer', 1), Opt('Vencido', 2)];
const dano = [Opt('Sin daño', 0), Opt('Dudoso', 1), Opt('Con daño', 2)];

const checklist = <Section>[
  Section('carroceria', 'Carrocería y pintura', 'Inspección visual 360° y medición de pintura',
      Icons.directions_car_outlined, [
    Item('car.visual', 'Inspección visual 360°', [Opt('Sin daños', 0), Opt('Detalles menores', 1), Opt('Daños', 2)],
        ayuda: 'Golpes, abolladuras, rayones y diferencias de tono.'),
    Item('car.pintura', 'Espesor de pintura', [Opt('Original', 0), Opt('Repintado', 1), Opt('Con masilla', 2)],
        ayuda: 'Medidor pieza por pieza. Anota en el comentario qué piezas.'),
    Item('car.paneles', 'Alineación de paneles', estado),
    Item('car.oxido', 'Óxido', [Opt('Sin óxido', 0), Opt('Superficial', 1), Opt('Avanzado', 2)]),
    Item('car.vidrios', 'Parabrisas y vidrios', estado),
    Item('car.opticas', 'Ópticas y focos', estado, ayuda: 'Estado físico; el encendido se revisa en Interior.'),
  ]),
  Section('estructura', 'Estructura y chasis', 'Puertas, capó y maletero abiertos; chasis por debajo',
      Icons.shield_outlined, [
    Item('est.bisagras', 'Bisagras, pernos y sellos', [Opt('Sin intervención', 0), Opt('Dudoso', 1), Opt('Intervenidos', 2)],
        ayuda: 'Puertas, capó y maletero: pernos desmontados, sellos y pelos de fábrica.'),
    Item('est.estructura', 'Largueros, pilares y piso', dano),
    Item('est.chasis', 'Chasis: soldaduras y choques', dano, ayuda: 'Por atrás, por los lados y por debajo.'),
  ]),
  Section('motor', 'Motor', 'Fluidos, correas, fugas y cableado', Icons.settings_suggest_outlined, [
    Item('motor.refrig_estado', 'Refrigerante (medición)', cambio, ayuda: 'Con el medidor: punto de protección.'),
    Item('motor.refrig_nivel', 'Nivel y depósito de refrigerante', nivel),
    Item('motor.correas', 'Correas', cambio),
    Item('motor.fugas', 'Fugas en motor', fugas),
    Item('motor.cableado', 'Cableado', estado),
    Item('motor.freno_liq', 'Líquido de frenos', nivel),
    Item('motor.hidraulico', 'Líquido hidráulico de dirección', [...nivel, noAplica]),
    Item('motor.aceite_nivel', 'Nivel de aceite', nivel),
    Item('motor.tapa_aceite', 'Tapa de aceite', [Opt('Limpia', 0), Opt('Residuo leve', 1), Opt('Mayonesa o borra', 2)],
        ayuda: 'Con linterna, mirar hacia adentro si el motor lo permite.'),
    Item('motor.calentamiento', 'Señales de sobrecalentamiento', [Opt('Sin señales', 0), Opt('Dudoso', 1), Opt('Con señales', 2)]),
  ]),
  Section('bajos', 'Parte baja y suspensión', 'Fugas, palieres, bandejas, fuelles, amortiguadores y neumáticos',
      Icons.tire_repair_outlined, [
    Item('baj.fugas', 'Fugas por debajo', fugas),
    Item('baj.palieres', 'Palieres', estado),
    Item('baj.bandejas', 'Bandejas y bujes', cambio),
    Item('baj.fuelles', 'Fuelles', [Opt('Buenos', 0), Opt('Resecos', 1), Opt('Cortados o faltantes', 2)]),
    Item('baj.cremallera', 'Cremallera de dirección', fugas),
    Item('baj.amort_del', 'Amortiguadores delanteros', [Opt('Buenos', 0), Opt('Humedad', 1), Opt('Con fuga', 2)]),
    Item('baj.amort_tras', 'Amortiguadores traseros', [Opt('Buenos', 0), Opt('Humedad', 1), Opt('Con fuga', 2)]),
    Item('baj.neumaticos', 'Neumáticos', [Opt('Buen desgaste', 0), Opt('Desgaste medio', 1), Opt('Para cambio', 2)],
        ayuda: 'Desgaste parejo o irregular (alineación).'),
  ]),
  Section('interior', 'Interior y electricidad', 'Cinturones, asientos, eléctrico, mandos y luces',
      Icons.airline_seat_recline_normal_outlined, [
    Item('int.cinturones', 'Cinturones', funciona),
    Item('int.asientos', 'Asientos y tapicería', estado),
    Item('int.electrico', 'Alzavidrios, espejos y cierre', funciona),
    Item('int.radio', 'Radio y multimedia', funciona),
    Item('int.volante', 'Comandos al volante', funciona),
    Item('int.parasoles', 'Parasoles y techo', estado),
    Item('int.aire', 'Aire acondicionado y calefacción', funciona),
    Item('int.luces', 'Luces e intermitentes', funciona, ayuda: 'Mientras el escáner reconoce el auto: encender todas.'),
    Item('int.testigos', 'Testigos del tablero', [Opt('Sin testigos', 0), Opt('Testigo menor', 1), Opt('Testigos de falla', 2)]),
  ]),
  Section('escaner', 'Escáner', 'Códigos, kilometraje, parámetros en vivo y batería', Icons.memory_outlined, [
    Item('esc.codigos', 'Códigos de falla', [Opt('Sin códigos', 0), Opt('Históricos', 1), Opt('Activos', 2)],
        ayuda: 'Todos los módulos: motor, caja, ABS, airbag.'),
    Item('esc.km', 'Kilometraje real', [Opt('Coincide', 0), Opt('No se pudo leer', 1), Opt('No coincide', 2)]),
    Item('esc.parametros', 'Parámetros en vivo', [Opt('Normales', 0), Opt('Con desviación', 1), Opt('Anómalos', 2)]),
    Item('esc.caja', 'Caja automática: temperatura y nivel', [Opt('Normal', 0), Opt('Revisar', 1), Opt('Anómalo', 2), noAplica]),
    Item('esc.bateria', 'Batería y carga', cambio),
  ]),
  Section('ruta', 'Prueba de ruta', 'Motor, embrague, cambios y trenes en marcha', Icons.route_outlined, [
    Item('ruta.motor', 'Ruidos de motor', ruido),
    Item('ruta.potencia', 'Respuesta del motor', [Opt('Normal', 0), Opt('Algo débil', 1), Opt('Sin fuerza', 2)],
        ayuda: 'Que no se sienta chupado ni pesado.'),
    Item('ruta.embrague', 'Embrague / convertidor', cambio),
    Item('ruta.cambios', 'Paso de cambios', estado),
    Item('ruta.tren_del', 'Tren delantero', ruido),
    Item('ruta.tren_tras', 'Tren trasero', ruido),
    Item('ruta.frenado', 'Frenado', estado),
    Item('ruta.direccion', 'Dirección', estado),
    Item('ruta.4x4', 'Tracción 4x4', [...funciona, noAplica]),
  ]),
  Section('documentos', 'Documentos', 'Si el vendedor los muestra', Icons.description_outlined, [
    Item('doc.permiso', 'Permiso de circulación', [...docs, noAplica]),
    Item('doc.revision', 'Revisión técnica', [...docs, noAplica]),
    Item('doc.soap', 'Seguro obligatorio (SOAP)', [...docs, noAplica]),
    Item('doc.mantenciones', 'Historial de mantenciones', [Opt('Completo', 0), Opt('Incompleto', 1), Opt('Sin registro', 2), noAplica]),
  ]),
];

int get totalItems => checklist.fold(0, (n, s) => n + s.items.length);

/// Busca un punto por id (para mensajes y el informe).
(Section, Item)? findItem(String id) {
  for (final s in checklist) {
    for (final it in s.items) {
      if (it.id == id) return (s, it);
    }
  }
  return null;
}
