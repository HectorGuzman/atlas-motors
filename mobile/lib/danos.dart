import 'dart:math';

/// Mapa de daños de la carrocería, dibujado según el tipo de vehículo.
///
/// Muestra el vehículo "desplegado" con el frente hacia la derecha:
///   lado izquierdo · vista desde arriba · lado derecho · frente y atrás.
/// El inspector toca una pieza y anota qué tiene.
///
/// Todo se dibuja con formas ([Forma]) en un espacio de [mapaAncho] x [mapaAlto]
/// unidades. La app (Flutter), el PDF y la web usan las mismas formas: a la web
/// se le publica el dibujo ya hecho (trazos SVG), así no hay que mantener dos copias.

const mapaAncho = 340.0;
const mapaAlto = 566.0;

/// Tipos de vehículo: id -> (nombre, nombre corto para el selector).
const tiposCarroceria = <String, (String, String)>{
  'sedan': ('Sedán', 'Sedán'),
  'hatch5': ('Hatchback 5 puertas', 'Hatchback 5p'),
  'hatch3': ('Hatchback 3 puertas', 'Hatchback 3p'),
  'suv': ('SUV o station wagon', 'SUV'),
  'pickup2': ('Camioneta doble cabina', 'Doble cabina'),
  'pickup1': ('Camioneta cabina simple', 'Cabina simple'),
  'furgon': ('Furgón', 'Furgón'),
};

// ───────────────────────── Formas ─────────────────────────

class P {
  final double x, y;
  const P(this.x, this.y);
  P operator +(P o) => P(x + o.x, y + o.y);
  P operator -(P o) => P(x - o.x, y - o.y);
  P operator *(double k) => P(x * k, y * k);
  double get largo => sqrt(x * x + y * y);
}

enum Cmd { m, l, c, z }

/// Una figura: lista de trazos (mover, línea, curva, cerrar) y el contorno
/// sin redondear, para saber si un toque cayó adentro.
class Forma {
  final List<(Cmd, List<P>)> cmds;
  final List<P> contorno;
  final P? centroCirculo;
  final double radioCirculo;
  final bool abierta; // línea (sin relleno)
  Forma._(this.cmds, this.contorno, {this.centroCirculo, this.radioCirculo = 0, this.abierta = false});

  /// Polígono con esquinas redondeadas ([radios] por vértice, o [r] para todas).
  factory Forma.poligono(List<P> pts, {double r = 0, List<double>? radios}) {
    const k = 0.55;
    final n = pts.length;
    final a = <P>[], b = <P>[];
    for (var i = 0; i < n; i++) {
      final cur = pts[i], prev = pts[(i - 1 + n) % n], next = pts[(i + 1) % n];
      final dp = (prev - cur).largo, dn = (next - cur).largo;
      final rr = [radios?[i] ?? r, dp / 2, dn / 2].reduce(min);
      a.add(dp == 0 ? cur : cur + (prev - cur) * (rr / dp));
      b.add(dn == 0 ? cur : cur + (next - cur) * (rr / dn));
    }
    final cmds = <(Cmd, List<P>)>[(Cmd.m, [a[0]])];
    for (var i = 0; i < n; i++) {
      if (i > 0) cmds.add((Cmd.l, [a[i]]));
      if ((a[i] - b[i]).largo > .01) {
        cmds.add((Cmd.c, [a[i] + (pts[i] - a[i]) * k, b[i] + (pts[i] - b[i]) * k, b[i]]));
      }
    }
    cmds.add((Cmd.z, const []));
    return Forma._(cmds, pts);
  }

  factory Forma.rect(double l, double t, double r, double b, {double radio = 0, List<double>? radios}) =>
      Forma.poligono([P(l, t), P(r, t), P(r, b), P(l, b)], r: radio, radios: radios);

  factory Forma.circulo(P c, double r) {
    const k = 0.5523;
    final d = r * k;
    return Forma._([
      (Cmd.m, [P(c.x + r, c.y)]),
      (Cmd.c, [P(c.x + r, c.y + d), P(c.x + d, c.y + r), P(c.x, c.y + r)]),
      (Cmd.c, [P(c.x - d, c.y + r), P(c.x - r, c.y + d), P(c.x - r, c.y)]),
      (Cmd.c, [P(c.x - r, c.y - d), P(c.x - d, c.y - r), P(c.x, c.y - r)]),
      (Cmd.c, [P(c.x + d, c.y - r), P(c.x + r, c.y - d), P(c.x + r, c.y)]),
      (Cmd.z, const []),
    ], [P(c.x - r, c.y - r), P(c.x + r, c.y - r), P(c.x + r, c.y + r), P(c.x - r, c.y + r)],
        centroCirculo: c, radioCirculo: r);
  }

  factory Forma.linea(List<P> pts) =>
      Forma._([(Cmd.m, [pts.first]), for (final p in pts.skip(1)) (Cmd.l, [p])], pts, abierta: true);

  (double, double, double, double) get caja {
    var l = double.infinity, t = double.infinity, r = -double.infinity, b = -double.infinity;
    for (final p in contorno) {
      l = min(l, p.x);
      t = min(t, p.y);
      r = max(r, p.x);
      b = max(b, p.y);
    }
    return (l, t, r, b);
  }

  double get area {
    final (l, t, r, b) = caja;
    return (r - l) * (b - t);
  }

  P get centro {
    final (l, t, r, b) = caja;
    return P((l + r) / 2, (t + b) / 2);
  }

  bool contiene(double x, double y) {
    if (centroCirculo != null) return (P(x, y) - centroCirculo!).largo <= radioCirculo;
    var dentro = false;
    for (var i = 0, j = contorno.length - 1; i < contorno.length; j = i++) {
      final pi = contorno[i], pj = contorno[j];
      if ((pi.y > y) != (pj.y > y) && x < (pj.x - pi.x) * (y - pi.y) / (pj.y - pi.y) + pi.x) dentro = !dentro;
    }
    return dentro;
  }

  double distancia(double x, double y) {
    final (l, t, r, b) = caja;
    final dx = max(max(l - x, 0.0), x - r), dy = max(max(t - y, 0.0), y - b);
    return sqrt(dx * dx + dy * dy);
  }

  /// Trazo SVG (atributo d).
  String get svg {
    String n(double v) => v.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    final b = StringBuffer();
    for (final (c, ps) in cmds) {
      b.write(switch (c) { Cmd.m => 'M', Cmd.l => 'L', Cmd.c => 'C', Cmd.z => 'Z' });
      b.write(ps.map((p) => '${n(p.x)} ${n(p.y)}').join(' '));
    }
    return b.toString();
  }
}

/// Estilos de dibujo. La app y el PDF usan estos colores; la web los suyos (tema oscuro).
/// (relleno, borde, grosor del borde)
const estilos = <String, (int?, int?, double)>{
  'sombra': (0xFFE9EBE8, null, 0),
  'cuerpo': (0xFFF6F7F6, 0xFF66706B, .9),
  'panel': (0xFFF6F7F6, 0xFF66706B, .9),
  'vidrio': (0xFFC4D3DD, 0xFF3F4744, 1.1),
  'pilar': (0xFF3F4744, null, 0),
  'faro': (0xFFFDF1C8, 0xFF8C7A48, .8),
  'piloto': (0xFFE7948A, 0xFF97433A, .8),
  'parrilla': (0xFF353A37, null, 0),
  'clara': (null, 0xFFB9C0BC, .8),
  'llanta': (0xFF2A2E2C, null, 0),
  'rin': (0xFFDCE0DE, 0xFF7E8782, .7),
  'hueco': (0xFF59615C, null, 0),
  'maza': (0xFF8F9893, null, 0),
  'arco': (0xFFFFFFFF, null, 0),
  'borde': (null, 0xFF66706B, .9),
  'manilla': (0xFFDDE1DF, 0xFF66706B, .6),
  'placa': (0xFFFFFFFF, 0xFF8F9893, .6),
  'piso': (0xFFE8EAE8, 0xFFA5ADA8, .6),
  'linea': (null, 0xFFA5ADA8, .7),
};

class Pieza {
  final Forma forma;
  final String estilo;
  final String? zona; // pieza que se puede marcar
  final String vista; // izq, sup, der, frente, atras
  const Pieza(this.forma, this.estilo, this.vista, [this.zona]);
}

class Texto {
  final String t;
  final double x, y, tam;
  final String ancla; // i = izquierda, c = centro, d = derecha
  const Texto(this.t, this.x, this.y, {this.ancla = 'i', this.tam = 8});
}

/// El dibujo de un tipo de vehículo.
class Mapa {
  final String tipo;
  final List<Pieza> piezas;
  final List<Texto> textos;
  final Map<String, String> nombres; // id de zona -> nombre para el informe
  Mapa(this.tipo, this.piezas, this.textos, this.nombres);

  /// La pieza tocada: la más chica que contiene el punto (un foco gana al
  /// parachoques) o, si se tocó justo al lado, la más cercana.
  String? zonaEn(double x, double y) {
    Pieza? mejor;
    for (final p in piezas) {
      if (p.zona != null && p.forma.contiene(x, y) && (mejor == null || p.forma.area < mejor.forma.area)) mejor = p;
    }
    if (mejor != null) return mejor.zona;
    var d = 9.0;
    for (final p in piezas) {
      if (p.zona == null) continue;
      final dz = p.forma.distancia(x, y);
      if (dz < d) {
        d = dz;
        mejor = p;
      }
    }
    return mejor?.zona;
  }

  /// Dónde poner el número de un daño en esta pieza (si se cambió el tipo de vehículo).
  /// Busca un punto dentro de la pieza, cerca de su centro, que no caiga sobre
  /// una rueda, un foco o un espejo.
  P? centroDe(String zona) {
    Pieza? pieza;
    for (final p in piezas) {
      if (p.zona == zona) {
        pieza = p;
        break;
      }
    }
    if (pieza == null) return null;
    final f = pieza.forma, c = f.centro;
    if (pieza.estilo == 'llanta') return c;
    final estorbos = [
      for (final p in piezas)
        if (p.estilo == 'arco' || (p.zona != null && p.zona != zona && p.forma.area < f.area && p.estilo != 'llanta')) p.forma,
    ];
    final (l, t, r, b) = f.caja;
    P? mejor;
    var dm = double.infinity;
    for (var x = l + 8; x <= r - 8; x += 2.5) {
      for (var y = t + 8; y <= b - 8; y += 2.5) {
        if (!f.contiene(x, y)) continue;
        final libre = estorbos.every((e) => e.centroCirculo != null
            ? (P(x, y) - e.centroCirculo!).largo > e.radioCirculo + 12
            : !e.contiene(x, y) && e.distancia(x, y) > 8);
        if (!libre) continue;
        final d = (P(x, y) - c).largo;
        if (d < dm) {
          dm = d;
          mejor = P(x, y);
        }
      }
    }
    return mejor ?? c;
  }

  /// La forma que contiene el punto, para dejar el número dentro de la pieza.
  Forma? formaEn(String zona, double x, double y) {
    Forma? f;
    for (final p in piezas) {
      if (p.zona == zona && (f == null || p.forma.distancia(x, y) < f.distancia(x, y))) f = p.forma;
    }
    return f;
  }

  /// Para publicar en la web: el dibujo listo.
  Map<String, dynamic> toJson() => {
        'tipo': tipo,
        'w': mapaAncho,
        'h': mapaAlto,
        'p': [for (final p in piezas) {'d': p.forma.svg, 'e': p.estilo, 'z': p.zona ?? '', if (p.forma.abierta) 'a': 1}],
        't': [for (final t in textos) {'t': t.t, 'x': t.x, 'y': t.y, 'a': t.ancla, 's': t.tam}],
      };
}

final _cache = <String, Mapa>{};

/// El dibujo del tipo pedido (sedán si no se conoce).
Mapa mapaDe(String tipo) => _cache.putIfAbsent(tipo, () => _construir(_vehiculos[tipo] != null ? tipo : 'sedan'));

// ───────────────────────── Tipos de vehículo ─────────────────────────
//
// Cada tipo se describe en METROS, con medidas reales aproximadas de un modelo
// típico del segmento (largo, alto, ancho, ejes, ruedas). Los contornos son
// puntos por los que pasa una curva suave; `true` marca una esquina viva.
// En los costados, x va de la cola (0) a la trompa (largo) e y es la altura.

typedef _K = Record; // (x, y) o (x, y, esquinaViva)

(double, double, bool) _k(Record r) => switch (r) {
      (num a, num b, bool c) => (a.toDouble(), b.toDouble(), c),
      (num a, num b) => (a.toDouble(), b.toDouble(), false),
      _ => throw ArgumentError(r),
    };

class _V {
  final double largo, alto, ancho, radio, ejeT, ejeD;
  final List<_K> silueta; // costado, cerrado: de la cola abajo, por el techo, a la trompa y de vuelta por abajo
  final List<_K> vidrios; // contorno de los vidrios laterales (cerrado)
  final List<(double, double)> pilares; // franjas oscuras entre vidrios (x desde, x hasta)
  final List<(double, double)> cortes; // juntas de puertas: (x abajo, x arriba)
  final List<String> piezas; // nombre de cada tramo entre juntas, de atrás hacia adelante
  final List<(double, double)>? cortesDer;
  final List<String>? piezasDer;
  final double paraT, paraD; // hasta dónde llegan los parachoques (x) y su altura
  final double altoPara;
  final double cintura; // altura de la base de los vidrios
  final double techoFrente; // ancho del techo visto de frente (proporción del ancho)
  final String trasera; // sedan, porton, caja, furgon
  // Vista desde arriba: base del parabrisas, inicio del parabrisas en el techo,
  // fin del techo y base de la luneta (o frente de la caja).
  final double capoDesde, techoHasta, techoDesde, lunetaDesde;
  final bool rieles;
  const _V({
    required this.largo,
    required this.alto,
    required this.ancho,
    required this.radio,
    required this.ejeT,
    required this.ejeD,
    required this.silueta,
    required this.vidrios,
    required this.pilares,
    required this.cortes,
    required this.piezas,
    this.cortesDer,
    this.piezasDer,
    required this.paraT,
    required this.paraD,
    required this.altoPara,
    required this.cintura,
    required this.techoFrente,
    required this.trasera,
    required this.capoDesde,
    required this.techoHasta,
    required this.techoDesde,
    required this.lunetaDesde,
    this.rieles = false,
  });
}

const _hatchSil = <_K>[
  (0.05, 0.30, true), (0.00, 0.50), (0.01, 0.86), (0.07, 1.16), (0.24, 1.41), (0.58, 1.49), (1.90, 1.50), (2.22, 1.42),
  (2.72, 1.02), (3.35, 0.90), (3.80, 0.77), (3.92, 0.56), (3.89, 0.36), (3.74, 0.27, true), (0.20, 0.27, true),
];
const _hatchVid = <_K>[(0.20, 1.03, true), (0.29, 1.29), (0.60, 1.42), (1.90, 1.43), (2.20, 1.35), (2.64, 1.04, true)];

const _vehiculos = <String, _V>{
  'sedan': _V(
    largo: 4.63, alto: 1.44, ancho: 1.78, radio: 0.315, ejeT: 0.98, ejeD: 3.68,
    silueta: [
      (0.06, 0.30, true), (0.00, 0.50), (0.02, 0.78), (0.30, 0.95), (0.82, 1.00), (1.30, 1.29), (1.76, 1.42),
      (2.60, 1.44), (3.05, 1.30), (3.50, 1.00), (4.12, 0.89), (4.50, 0.77), (4.62, 0.56), (4.59, 0.36),
      (4.45, 0.26, true), (0.24, 0.26, true),
    ],
    vidrios: [(1.00, 1.02, true), (1.44, 1.30), (1.84, 1.385), (2.58, 1.39), (3.00, 1.26), (3.36, 1.03, true)],
    pilares: [(1.52, 1.60), (2.32, 2.40)],
    cortes: [(1.46, 1.60), (2.36, 2.36), (3.24, 3.38)],
    piezas: ['costado_tras', 'puerta_tras', 'puerta_del', 'tapabarro_del'],
    paraT: 0.40, paraD: 4.25, altoPara: 0.60, cintura: 1.00, techoFrente: 0.66, trasera: 'sedan',
    capoDesde: 3.50, techoHasta: 2.62, techoDesde: 1.70, lunetaDesde: 0.84,
  ),
  'hatch5': _V(
    largo: 3.92, alto: 1.50, ancho: 1.72, radio: 0.30, ejeT: 0.66, ejeD: 3.16,
    silueta: _hatchSil, vidrios: _hatchVid,
    pilares: [(0.62, 0.78), (1.62, 1.70)],
    cortes: [(0.98, 0.76), (1.66, 1.66), (2.60, 2.72)],
    piezas: ['costado_tras', 'puerta_tras', 'puerta_del', 'tapabarro_del'],
    paraT: 0.32, paraD: 3.58, altoPara: 0.60, cintura: 1.02, techoFrente: 0.70, trasera: 'porton',
    capoDesde: 2.75, techoHasta: 1.95, techoDesde: 0.55, lunetaDesde: 0.10,
  ),
  'hatch3': _V(
    largo: 3.92, alto: 1.48, ancho: 1.72, radio: 0.30, ejeT: 0.66, ejeD: 3.16,
    silueta: _hatchSil, vidrios: _hatchVid,
    pilares: [(0.95, 1.10)],
    cortes: [(1.12, 1.04), (2.60, 2.72)],
    piezas: ['costado_tras', 'puerta_del', 'tapabarro_del'],
    paraT: 0.32, paraD: 3.58, altoPara: 0.60, cintura: 1.02, techoFrente: 0.70, trasera: 'porton',
    capoDesde: 2.75, techoHasta: 1.95, techoDesde: 0.55, lunetaDesde: 0.10,
  ),
  'suv': _V(
    largo: 4.55, alto: 1.68, ancho: 1.85, radio: 0.36, ejeT: 0.95, ejeD: 3.64,
    silueta: [
      (0.06, 0.36, true), (0.00, 0.58), (0.01, 1.00), (0.06, 1.38), (0.20, 1.61), (0.50, 1.68), (2.55, 1.68),
      (2.95, 1.53), (3.40, 1.13), (4.10, 1.03), (4.47, 0.91), (4.55, 0.64), (4.50, 0.42), (4.34, 0.33, true),
      (0.22, 0.33, true),
    ],
    vidrios: [(0.14, 1.15, true), (0.20, 1.44), (0.45, 1.585), (2.52, 1.59), (2.88, 1.46), (3.30, 1.17, true)],
    pilares: [(0.56, 0.70), (1.38, 1.46), (2.28, 2.36)],
    cortes: [(1.42, 1.42), (2.32, 2.32), (3.24, 3.36)],
    piezas: ['costado_tras', 'puerta_tras', 'puerta_del', 'tapabarro_del'],
    paraT: 0.36, paraD: 4.20, altoPara: 0.66, cintura: 1.14, techoFrente: 0.76, trasera: 'porton',
    capoDesde: 3.40, techoHasta: 2.55, techoDesde: 0.40, lunetaDesde: 0.08, rieles: true,
  ),
  'pickup2': _V(
    largo: 5.33, alto: 1.82, ancho: 1.86, radio: 0.385, ejeT: 1.20, ejeD: 4.29,
    silueta: [
      (0.04, 0.45, true), (0.00, 0.62), (0.01, 1.12, true), (1.97, 1.12, true), (2.00, 1.66), (2.06, 1.77), (2.20, 1.82),
      (3.22, 1.82), (3.60, 1.63), (3.95, 1.23), (4.75, 1.13), (5.20, 1.02), (5.33, 0.76), (5.28, 0.49),
      (5.10, 0.40, true), (0.20, 0.42, true),
    ],
    vidrios: [(2.10, 1.24, true), (2.11, 1.64), (2.22, 1.745), (3.20, 1.745), (3.54, 1.59), (3.86, 1.26, true)],
    pilares: [(2.92, 3.00)],
    cortes: [(1.98, 1.98), (2.96, 2.96), (3.86, 3.98)],
    piezas: ['costado_tras', 'puerta_tras', 'puerta_del', 'tapabarro_del'],
    paraT: 0.30, paraD: 4.95, altoPara: 0.66, cintura: 1.22, techoFrente: 0.76, trasera: 'caja',
    capoDesde: 3.95, techoHasta: 3.28, techoDesde: 2.10, lunetaDesde: 1.98,
  ),
  'pickup1': _V(
    largo: 5.27, alto: 1.80, ancho: 1.86, radio: 0.385, ejeT: 1.14, ejeD: 4.23,
    silueta: [
      (0.04, 0.45, true), (0.00, 0.62), (0.01, 1.12, true), (2.84, 1.12, true), (2.87, 1.66), (2.93, 1.76), (3.05, 1.80),
      (3.20, 1.80), (3.56, 1.61), (3.90, 1.22), (4.70, 1.12), (5.14, 1.01), (5.27, 0.76), (5.22, 0.49),
      (5.04, 0.40, true), (0.20, 0.42, true),
    ],
    vidrios: [(2.98, 1.24, true), (2.99, 1.63), (3.08, 1.725), (3.18, 1.725), (3.50, 1.58), (3.81, 1.25, true)],
    pilares: [],
    cortes: [(2.85, 2.85), (3.80, 3.92)],
    piezas: ['costado_tras', 'puerta_del', 'tapabarro_del'],
    paraT: 0.30, paraD: 4.90, altoPara: 0.66, cintura: 1.22, techoFrente: 0.76, trasera: 'caja',
    capoDesde: 3.90, techoHasta: 3.24, techoDesde: 2.96, lunetaDesde: 2.85,
  ),
  'furgon': _V(
    largo: 5.15, alto: 1.93, ancho: 1.92, radio: 0.34, ejeT: 1.03, ejeD: 4.23,
    silueta: [
      (0.04, 0.36, true), (0.00, 0.56), (0.00, 1.74), (0.06, 1.88), (0.26, 1.93), (3.70, 1.93), (4.06, 1.81),
      (4.46, 1.31), (4.95, 1.06), (5.13, 0.86), (5.15, 0.56), (5.08, 0.39), (4.95, 0.33, true), (0.20, 0.33, true),
    ],
    vidrios: [(3.56, 1.10, true), (3.58, 1.66), (3.72, 1.81), (3.98, 1.81), (4.30, 1.37, true)],
    pilares: [],
    cortes: [(3.52, 3.52), (4.32, 4.42)],
    piezas: ['costado_tras', 'puerta_del', 'tapabarro_del'],
    cortesDer: [(1.85, 1.85), (3.52, 3.52), (4.32, 4.42)],
    piezasDer: ['costado_tras', 'puerta_lateral', 'puerta_del', 'tapabarro_del'],
    paraT: 0.32, paraD: 4.82, altoPara: 0.62, cintura: 1.12, techoFrente: 0.86, trasera: 'furgon',
    capoDesde: 4.46, techoHasta: 3.90, techoDesde: 0.12, lunetaDesde: 0.0,
  ),
};

// ── Geometría en metros ──

typedef _Q = (double, double);

/// Curva suave (Catmull-Rom) que pasa por los puntos, muestreada cada ~4 cm.
List<_Q> _curva(List<_K> pts, {bool cerrada = true}) {
  final ks = [for (final r in pts) _k(r)];
  final n = ks.length;
  final out = <_Q>[];
  (double, double, bool) at(int i) => cerrada ? ks[(i % n + n) % n] : ks[i.clamp(0, n - 1)];
  _Q p(int i) => (at(i).$1, at(i).$2);
  bool viva(int i) => at(i).$3;
  final tramos = cerrada ? n : n - 1;
  for (var i = 0; i < tramos; i++) {
    final p0 = p(i - 1), p1 = p(i), p2 = p(i + 1), p3 = p(i + 2);
    final t1 = viva(i) ? (0.0, 0.0) : ((p2.$1 - p0.$1) * .5, (p2.$2 - p0.$2) * .5);
    final t2 = viva(i + 1) ? (0.0, 0.0) : ((p3.$1 - p1.$1) * .5, (p3.$2 - p1.$2) * .5);
    final largo = sqrt(pow(p2.$1 - p1.$1, 2) + pow(p2.$2 - p1.$2, 2));
    final pasos = max(2, (largo / 0.04).ceil());
    for (var s = 0; s < pasos; s++) {
      final t = s / pasos, t2_ = t * t, t3 = t2_ * t;
      final h1 = 2 * t3 - 3 * t2_ + 1, h2 = -2 * t3 + 3 * t2_, h3 = t3 - 2 * t2_ + t, h4 = t3 - t2_;
      out.add((h1 * p1.$1 + h2 * p2.$1 + h3 * t1.$1 + h4 * t2.$1, h1 * p1.$2 + h2 * p2.$2 + h3 * t1.$2 + h4 * t2.$2));
    }
  }
  if (!cerrada) out.add(p(n - 1));
  return out;
}

/// Recorta un polígono y deja solo lo que cumple [dentro] (un semiplano).
List<_Q> _recortar(List<_Q> pol, bool Function(_Q) dentro, _Q Function(_Q, _Q) corte) {
  if (pol.isEmpty) return pol;
  final out = <_Q>[];
  for (var i = 0; i < pol.length; i++) {
    final a = pol[i], b = pol[(i + 1) % pol.length];
    final ia = dentro(a), ib = dentro(b);
    if (ia) out.add(a);
    if (ia != ib) out.add(corte(a, b));
  }
  return out;
}

/// Deja lo que queda a la izquierda de la recta a→b (mirando de a hacia b, con y hacia arriba).
List<_Q> _lado(List<_Q> pol, _Q a, _Q b) {
  double f(_Q p) => (b.$1 - a.$1) * (p.$2 - a.$2) - (b.$2 - a.$2) * (p.$1 - a.$1);
  return _recortar(pol, (p) => f(p) >= 0, (p, q) {
    final fp = f(p), fq = f(q), t = fp / (fp - fq);
    return (p.$1 + (q.$1 - p.$1) * t, p.$2 + (q.$2 - p.$2) * t);
  });
}

List<_Q> _xMayor(List<_Q> pol, double x) => _lado(pol, (x, 10), (x, -10));
List<_Q> _xMenor(List<_Q> pol, double x) => _lado(pol, (x, -10), (x, 10));
List<_Q> _yMayor(List<_Q> pol, double y) => _lado(pol, (-10, y), (10, y));
List<_Q> _yMenor(List<_Q> pol, double y) => _lado(pol, (10, y), (-10, y));

/// Entre dos juntas inclinadas: a la derecha de la junta trasera y a la izquierda de la delantera.
List<_Q> _entre(List<_Q> pol, (double, double)? atras, (double, double)? adelante) {
  var r = pol;
  if (atras != null) r = _lado(r, (atras.$2, 3), (atras.$1, -1));
  if (adelante != null) r = _lado(r, (adelante.$1, -1), (adelante.$2, 3));
  return r;
}

List<_K> _espejoX(List<_K> pts) => [for (final p in pts.reversed.map(_k)) (-p.$1, p.$2, p.$3)];

Mapa _construir(String tipo) {
  final v = _vehiculos[tipo]!;
  const k = 56.0; // unidades por metro
  final piezas = <Pieza>[];
  final nombres = <String, String>{};
  final dosPuertas = !v.piezas.contains('puerta_tras');

  void zona(List<_Q> pol, P Function(_Q) t, String estilo, String vista, String base, [String? lado]) {
    if (pol.length < 3) return;
    final id = lado == null ? base : '${base}_$lado';
    nombres[id] = _nombre(base, lado, v.trasera, dosPuertas);
    piezas.add(Pieza(Forma.poligono([for (final q in pol) t(q)]), estilo, vista, id));
  }

  void adorno(List<_Q> pol, P Function(_Q) t, String estilo, String vista) {
    if (pol.length < 2) return;
    piezas.add(Pieza(Forma.poligono([for (final q in pol) t(q)]), estilo, vista));
  }

  void linea(List<_Q> pts, P Function(_Q) t, String estilo, String vista) =>
      piezas.add(Pieza(Forma.linea([for (final q in pts) t(q)]), estilo, vista));

  // Rectángulo con esquinas redondeadas (cuartos de círculo).
  List<_Q> rect(double x1, double y1, double x2, double y2, [double r = 0.03]) {
    r = min(r, min((x2 - x1).abs(), (y2 - y1).abs()) / 2);
    final out = <_Q>[];
    for (final (cx, cy, a0) in [(x2 - r, y1 + r, -pi / 2), (x2 - r, y2 - r, 0.0), (x1 + r, y2 - r, pi / 2), (x1 + r, y1 + r, pi)]) {
      for (var i = 0; i <= 6; i++) {
        final a = a0 + (pi / 2) * i / 6;
        out.add((cx + r * cos(a), cy + r * sin(a)));
      }
    }
    return out;
  }
  List<_Q> circulo(double cx, double cy, double r, [double desde = 0, double hasta = 2 * pi, int n = 40]) => [
        for (var i = 0; i <= n; i++) (cx + r * cos(desde + (hasta - desde) * i / n), cy + r * sin(desde + (hasta - desde) * i / n)),
      ];

  final x0 = (mapaAncho - v.largo * k) / 2;
  final silueta = _curva(v.silueta);
  final vidrios = _curva(v.vidrios);

  // ── Costados (frente a la derecha) ──
  void costado(String lado, double suelo) {
    final vista = lado;
    P t(_Q q) => P(x0 + q.$1 * k, suelo - q.$2 * k);
    adorno(rect(-0.08, -0.07, v.largo + 0.08, 0.0, 0.035), t, 'sombra', vista);
    final cortes = lado == 'der' && v.cortesDer != null ? v.cortesDer! : v.cortes;
    final nombresPiezas = lado == 'der' && v.piezasDer != null ? v.piezasDer! : v.piezas;
    for (var i = 0; i < nombresPiezas.length; i++) {
      final pol = _entre(silueta, i == 0 ? null : cortes[i - 1], i == cortes.length ? null : cortes[i]);
      zona(pol, t, 'panel', vista, nombresPiezas[i], lado);
    }
    // Parachoques y pisadera, encima de las piezas grandes.
    zona(_yMenor(_xMenor(silueta, v.paraT), v.altoPara), t, 'panel', vista, 'parachoques_tras');
    zona(_yMenor(_xMayor(silueta, v.paraD), v.altoPara), t, 'panel', vista, 'parachoques_del');
    final bajo = v.silueta.map((p) => _k(p).$2).reduce(min);
    zona(_yMenor(_entre(silueta, (v.ejeT + v.radio * 1.16, v.ejeT + v.radio * 1.16), (v.ejeD - v.radio * 1.16, v.ejeD - v.radio * 1.16)), bajo + 0.13),
        t, 'panel', vista, 'pisadera', lado);
    // Focos vistos de lado.
    adorno(_yMenor(_yMayor(_xMenor(silueta, 0.14), v.altoPara + 0.10), v.trasera == 'sedan' ? v.altoPara + 0.26 : v.altoPara + 0.42), t, 'piloto', vista);
    adorno(_yMenor(_yMayor(_xMayor(silueta, v.largo - 0.30), v.altoPara + 0.06), v.altoPara + 0.18), t, 'faro', vista);
    // Vidrios con su marco y pilares.
    adorno(vidrios, t, 'vidrio', vista);
    for (final (a, b) in v.pilares) {
      adorno(_xMenor(_xMayor(vidrios, a), b), t, 'pilar', vista);
    }
    if (tipo == 'furgon' && lado == 'der') {
      linea([(1.95, v.cintura + 0.52), (3.45, v.cintura + 0.52)], t, 'linea', vista);
    }
    // Línea de carrocería, manillas y espejo.
    final hl = v.altoPara + 0.18;
    linea(_curva([(0.18, hl + 0.02), (v.largo * .5, hl), (v.largo - 0.5, hl - 0.03)], cerrada: false), t, 'linea', vista);
    for (var i = 0; i < nombresPiezas.length; i++) {
      if (!nombresPiezas[i].startsWith('puerta')) continue;
      final xa = cortes[i - 1].$1 + (cortes[i - 1].$2 - cortes[i - 1].$1) * .55;
      adorno(rect(xa + 0.08, v.cintura - 0.11, xa + 0.24, v.cintura - 0.07, 0.02), t, 'manilla', vista);
    }
    final ultimoCorte = cortes.last;
    final ex = ultimoCorte.$2 - 0.08;
    zona(_curva([(ex - 0.20, v.cintura + 0.01, true), (ex - 0.02, v.cintura + 0.02), (ex + 0.02, v.cintura + 0.12), (ex - 0.10, v.cintura + 0.15), (ex - 0.22, v.cintura + 0.10)]),
        t, 'panel', vista, 'espejo', lado);
    // Ruedas: el arco corta la carrocería y adentro va el neumático con su llanta.
    for (final (base, eje) in [('rueda_tras', v.ejeT), ('rueda_del', v.ejeD)]) {
      final ra = v.radio * 1.16;
      adorno(circulo(eje, v.radio, ra, 0, 2 * pi), t, 'arco', vista);
      linea(circulo(eje, v.radio, ra, 0.05 * pi, 0.95 * pi, 28), t, 'borde', vista);
      zona(circulo(eje, v.radio, v.radio), t, 'llanta', vista, base, lado);
      adorno(circulo(eje, v.radio, v.radio * .68), t, 'rin', vista);
      for (var j = 0; j < 5; j++) {
        final a = pi / 2 + j * 2 * pi / 5;
        adorno(circulo(eje + cos(a) * v.radio * .40, v.radio + sin(a) * v.radio * .40, v.radio * .15, 0, 2 * pi, 16), t, 'hueco', vista);
      }
      adorno(circulo(eje, v.radio, v.radio * .14, 0, 2 * pi, 16), t, 'maza', vista);
    }
  }

  // ── Desde arriba (frente a la derecha; el lado izquierdo queda arriba) ──
  void arriba(double cy) {
    const vista = 'sup';
    final w = v.ancho / 2, l = v.largo;
    P t(_Q q) => P(x0 + q.$1 * k, cy - q.$2 * k);
    final contorno = _curva([
      (0.00, 0.0), (0.01, w * .74), (0.10, w * .95), (0.50, w), (l - 0.95, w), (l - 0.30, w * .95), (l - 0.04, w * .74),
      (l, 0.0), (l - 0.04, -w * .74), (l - 0.30, -w * .95), (l - 0.95, -w), (0.50, -w), (0.10, -w * .95), (0.01, -w * .74),
    ]);
    adorno(contorno, t, 'cuerpo', vista);
    final dentro = _yMenor(_yMayor(contorno, -w * .90), w * .90);
    zona(_xMayor(contorno, l - 0.20), t, 'panel', vista, 'parachoques_del');
    zona(_xMenor(_xMayor(dentro, v.capoDesde + 0.03), l - 0.22), t, 'panel', vista, 'capo');
    if (v.capoDesde < l - 0.8) {
      for (final s in [-1.0, 1.0]) {
        linea(_curva([(v.capoDesde + 0.15, s * w * .42), (l - 0.45, s * w * .36)], cerrada: false), t, 'linea', vista);
      }
    }
    zona(_curva([
      (v.techoHasta, w * .70, true), (v.capoDesde - 0.02, w * .84, true), (v.capoDesde + 0.04, 0),
      (v.capoDesde - 0.02, -w * .84, true), (v.techoHasta, -w * .70, true), (v.techoHasta + 0.03, 0),
    ]), t, 'vidrio', vista, 'parabrisas');
    zona(rect(v.techoDesde, -w * .72, v.techoHasta - 0.03, w * .72, 0.10), t, 'panel', vista, 'techo');
    if (v.rieles) {
      for (final s in [-1.0, 1.0]) {
        linea([(v.techoDesde + 0.15, s * w * .62), (v.techoHasta - 0.15, s * w * .62)], t, 'borde', vista);
      }
    }
    switch (v.trasera) {
      case 'sedan':
        zona(_curva([
          (v.lunetaDesde, w * .76, true), (v.techoDesde - 0.02, w * .72, true), (v.techoDesde - 0.05, 0),
          (v.techoDesde - 0.02, -w * .72, true), (v.lunetaDesde, -w * .76, true), (v.lunetaDesde - 0.03, 0),
        ]), t, 'vidrio', vista, 'luneta');
        zona(_xMenor(_xMayor(dentro, 0.16), v.lunetaDesde - 0.03), t, 'panel', vista, 'maletero');
      case 'porton':
        zona(_curva([
          (v.lunetaDesde, w * .72, true), (v.techoDesde - 0.02, w * .72, true), (v.techoDesde - 0.02, -w * .72, true),
          (v.lunetaDesde, -w * .72, true), (v.lunetaDesde - 0.03, 0),
        ]), t, 'vidrio', vista, 'luneta');
      case 'caja':
        zona(rect(v.lunetaDesde + 0.02, -w * .66, v.techoDesde - 0.01, w * .66, 0.02), t, 'vidrio', vista, 'luneta');
        zona(_xMenor(_xMayor(_yMenor(_yMayor(contorno, -w * .94), w * .94), 0.14), v.lunetaDesde - 0.03), t, 'panel', vista, 'caja');
        adorno(rect(0.22, -w * .80, v.lunetaDesde - 0.10, w * .80, 0.04), t, 'piso', vista);
        for (var x = 0.45; x < v.lunetaDesde - 0.2; x += 0.30) {
          linea([(x, -w * .76), (x, w * .76)], t, 'linea', vista);
        }
      case 'furgon':
        for (var x = 0.6; x < v.techoHasta - 0.3; x += 0.55) {
          linea([(x, -w * .66), (x, w * .66)], t, 'linea', vista);
        }
    }
    zona(_xMenor(contorno, 0.14), t, 'panel', vista, 'parachoques_tras');
    final ex = v.capoDesde - 0.10;
    for (final (s, lado) in [(1.0, 'izq'), (-1.0, 'der')]) {
      zona(_curva([(ex - 0.16, s * w, true), (ex + 0.02, s * w, true), (ex - 0.02, s * (w + 0.15)), (ex - 0.14, s * (w + 0.14))]),
          t, 'panel', vista, 'espejo', lado);
    }
  }

  // ── Frente y atrás. De frente, el lado izquierdo del vehículo queda a la derecha del dibujo. ──
  void extremo(bool frente, double cx, double suelo) {
    final vista = frente ? 'frente' : 'atras';
    final w = v.ancho / 2, h = v.alto, c = v.cintura, rt = v.techoFrente;
    P t(_Q q) => P(cx + q.$1 * k, suelo - q.$2 * k);
    adorno(rect(-w - 0.06, -0.07, w + 0.06, 0.0, 0.035), t, 'sombra', vista);
    for (final s in [-1.0, 1.0]) {
      adorno(rect(s < 0 ? -w * .96 : w * .64, 0.0, s < 0 ? -w * .64 : w * .96, 0.30, 0.05), t, 'llanta', vista);
    }
    final mitad = <_K>[
      (w * .93, 0.20, true), (w * .99, 0.42), (w, 0.66), (w * .97, c - 0.04), (w * .88, c + 0.03),
      (w * (rt + .12), h - 0.10), (w * rt * .80, h), (0.0, h + 0.012),
    ];
    final cuerpo = _curva([...mitad, ..._espejoX(mitad).skip(1)]);
    adorno(cuerpo, t, 'cuerpo', vista);
    final izqA = frente ? 'der' : 'izq', derA = frente ? 'izq' : 'der';
    final sAlto = v.trasera == 'caja' || tipo == 'suv' || v.trasera == 'furgon';
    final yFaro = sAlto ? 0.82 : 0.66;
    if (frente) {
      zona(_curva([
        (-w * .84, c + 0.06, true), (w * .84, c + 0.06, true), (w * (rt + .05), h - 0.08, true), (0.0, h - 0.06),
        (-w * (rt + .05), h - 0.08, true),
      ]), t, 'vidrio', vista, 'parabrisas');
      zona(_yMenor(_yMayor(cuerpo, yFaro + 0.15), c + 0.03), t, 'panel', vista, 'capo');
      for (final (s, lado) in [(-1.0, izqA), (1.0, derA)]) {
        zona(_curva([(s * w * .40, yFaro, true), (s * w * .90, yFaro + 0.03, true), (s * w * .94, yFaro + 0.13, true), (s * w * .46, yFaro + 0.12, true)]),
            t, 'faro', vista, 'foco_del', lado);
        zona(_curva([(s * (w - 0.01), c - 0.01, true), (s * (w + 0.16), c + 0.02), (s * (w + 0.17), c + 0.13), (s * (w + 0.02), c + 0.12, true)]),
            t, 'panel', vista, 'espejo', lado);
      }
      adorno(_curva([(-w * .36, yFaro - 0.16, true), (w * .36, yFaro - 0.16, true), (w * .34, yFaro + 0.10, true), (-w * .34, yFaro + 0.10, true)]),
          t, 'parrilla', vista);
      for (var g = 1; g <= 3; g++) {
        final y = yFaro - 0.16 + g * 0.065;
        linea([(-w * .33, y), (w * .33, y)], t, 'clara', vista);
      }
      zona(_yMenor(cuerpo, yFaro - 0.20), t, 'panel', vista, 'parachoques_del');
      adorno(rect(-w * .50, 0.24, w * .50, 0.34, 0.04), t, 'parrilla', vista);
      adorno(rect(-0.26, 0.35, 0.26, 0.45, 0.012), t, 'placa', vista);
      for (final s in [-1.0, 1.0]) {
        adorno(circulo(s * w * .76, 0.30, 0.04, 0, 2 * pi, 16), t, 'faro', vista);
      }
    } else {
      switch (v.trasera) {
        case 'sedan':
          zona(_curva([(-w * .80, c + 0.07, true), (w * .80, c + 0.07, true), (w * (rt + .02), h - 0.08, true), (0.0, h - 0.06), (-w * (rt + .02), h - 0.08, true)]),
              t, 'vidrio', vista, 'luneta');
          zona(_yMenor(_yMayor(_xMenor(_xMayor(cuerpo, -w * .84), w * .84), 0.58), c + 0.04), t, 'panel', vista, 'maletero');
        case 'porton':
          zona(_yMayor(_xMenor(_xMayor(cuerpo, -w * .80), w * .80), 0.58), t, 'panel', vista, 'maletero');
          zona(_curva([(-w * .74, c + 0.08, true), (w * .74, c + 0.08, true), (w * (rt - .02), h - 0.10, true), (0.0, h - 0.08), (-w * (rt - .02), h - 0.10, true)]),
              t, 'vidrio', vista, 'luneta');
          adorno(_yMayor(_xMenor(_xMayor(cuerpo, -w * (rt + .02)), w * (rt + .02)), h - 0.06), t, 'pilar', vista);
        case 'caja':
          zona(rect(-w * .52, c + 0.14, w * .52, h - 0.14, 0.05), t, 'vidrio', vista, 'luneta');
          zona(_yMenor(_yMayor(_xMenor(_xMayor(cuerpo, -w * .88), w * .88), 0.62), 1.12), t, 'panel', vista, 'maletero');
          linea([(-w * .80, 1.04), (w * .80, 1.04)], t, 'linea', vista);
        case 'furgon':
          zona(_yMenor(_yMayor(_xMenor(_xMayor(cuerpo, -w * .86), w * .86), 0.58), h - 0.05), t, 'panel', vista, 'maletero');
          adorno(rect(-w * .78, c + 0.10, -0.04, h - 0.18, 0.05), t, 'vidrio', vista);
          adorno(rect(0.04, c + 0.10, w * .78, h - 0.18, 0.05), t, 'vidrio', vista);
          linea([(0.0, 0.60), (0.0, h - 0.07)], t, 'borde', vista);
      }
      final alto = v.trasera == 'sedan' ? (0.70, 0.86) : (sAlto ? (0.70, 1.06) : (0.72, 0.98));
      for (final (s, lado) in [(-1.0, izqA), (1.0, derA)]) {
        zona(_curva([(s * w * .70, alto.$1, true), (s * w * .99, alto.$1, true), (s * w * .99, alto.$2, true), (s * w * .76, alto.$2, true)]),
            t, 'piloto', vista, 'foco_tras', lado);
      }
      zona(_yMenor(cuerpo, 0.56), t, 'panel', vista, 'parachoques_tras');
      adorno(rect(-0.26, 0.42, 0.26, 0.52, 0.012), t, 'placa', vista);
    }
  }

  costado('izq', 128);
  arriba(213);
  costado('der', 412);
  extremo(true, 85, 548);
  extremo(false, 255, 548);

  final hw = v.ancho / 2 * k;
  const ts = 8.0;
  final textos = <Texto>[
    const Texto('LADO IZQUIERDO', 10, 8, tam: ts),
    const Texto('FRENTE ›', 330, 8, ancla: 'd', tam: ts),
    const Texto('DESDE ARRIBA', 10, 144, tam: ts),
    const Texto('FRENTE ›', 330, 144, ancla: 'd', tam: ts),
    const Texto('LADO DERECHO', 10, 292, tam: ts),
    const Texto('FRENTE ›', 330, 292, ancla: 'd', tam: ts),
    const Texto('FRENTE', 85, 428, ancla: 'c', tam: ts),
    const Texto('ATRÁS', 255, 428, ancla: 'c', tam: ts),
    Texto('der.', 85 - hw + 6, 560, ancla: 'c', tam: 7),
    Texto('izq.', 85 + hw - 6, 560, ancla: 'c', tam: 7),
    Texto('izq.', 255 - hw + 6, 560, ancla: 'c', tam: 7),
    Texto('der.', 255 + hw - 6, 560, ancla: 'c', tam: 7),
  ];
  return Mapa(tipo, piezas, textos, nombres);
}

/// Nombre para el informe de una pieza (id sin el lado) y su lado.
String _nombre(String base, String? lado, String trasera, bool dosPuertas) {
  final femenino = base.startsWith('puerta') || base.startsWith('rueda') || base == 'pisadera';
  final l = lado == null ? '' : (lado == 'izq' ? (femenino ? ' izquierda' : ' izquierdo') : (femenino ? ' derecha' : ' derecho'));
  return switch (base) {
    'costado_tras' => switch (trasera) {
        'caja' => 'Lateral de la caja, lado${lado == 'izq' ? ' izquierdo' : ' derecho'}',
        'furgon' => 'Costado de carga$l',
        _ => 'Costado trasero$l',
      },
    'puerta_del' => '${dosPuertas ? 'Puerta' : 'Puerta delantera'}$l',
    'puerta_tras' => 'Puerta trasera$l',
    'puerta_lateral' => 'Puerta corredera$l',
    'tapabarro_del' => 'Tapabarro delantero$l',
    'pisadera' => 'Pisadera$l',
    'espejo' => 'Espejo$l',
    'rueda_del' => 'Rueda delantera$l',
    'rueda_tras' => 'Rueda trasera$l',
    'foco_del' => 'Foco delantero$l',
    'foco_tras' => 'Foco trasero$l',
    'capo' => 'Capó',
    'parabrisas' => 'Parabrisas',
    'techo' => trasera == 'caja' ? 'Techo de la cabina' : 'Techo',
    'luneta' => trasera == 'caja' ? 'Vidrio trasero de la cabina' : 'Luneta',
    'maletero' => switch (trasera) {
        'sedan' => 'Tapa del maletero',
        'caja' => 'Portón de la caja',
        'furgon' => 'Puertas traseras',
        _ => 'Portalón',
      },
    'caja' => 'Caja de carga',
    'parachoques_del' => 'Parachoques delantero',
    'parachoques_tras' => 'Parachoques trasero',
    _ => base,
  };
}

// ───────────────────────── Daños ─────────────────────────

/// Tipos de daño y la gravedad que se propone para cada uno (1 = detalle, 2 = importante).
const tiposDano = ['Rayón', 'Abolladura', 'Repintado', 'Con masilla', 'Óxido', 'Trizado o quebrado', 'Descuadrado', 'Otro'];
const gravedadSugerida = [1, 1, 1, 2, 1, 2, 2, 1];
const gravedades = {1: 'Detalle', 2: 'Importante'};

/// Un daño marcado en el mapa.
class Dano {
  String zona; // id de la pieza (ej. puerta_del_izq)
  String pieza; // nombre de la pieza al marcarlo (ej. "Puerta delantera izquierda")
  int tipo; // índice en [tiposDano]
  int sev; // 1 = detalle, 2 = importante
  double x, y; // dónde va el número, en unidades del mapa (-1 = sin ubicación)
  String nota;
  List<String> fotos;

  Dano({required this.zona, this.pieza = '', required this.tipo, required this.sev, required this.x, required this.y, this.nota = '', List<String>? fotos})
      : fotos = fotos ?? [];

  String get nombreZona => pieza.isNotEmpty ? pieza : zona;
  String get nombreTipo => tiposDano[tipo.clamp(0, tiposDano.length - 1)];
  bool get ubicado => x >= 0 && y >= 0;

  Map<String, dynamic> toJson() =>
      {'zona': zona, 'pieza': pieza, 'tipo': tipo, 'sev': sev, 'x': x, 'y': y, 'nota': nota, 'fotos': fotos};

  factory Dano.fromJson(Map<String, dynamic> j) => Dano(
        zona: j['zona'] ?? '', pieza: j['pieza'] ?? '', tipo: j['tipo'] ?? 0, sev: j['sev'] ?? 1,
        x: (j['x'] as num? ?? -1).toDouble(), y: (j['y'] as num? ?? -1).toDouble(),
        nota: j['nota'] ?? '', fotos: List<String>.from(j['fotos'] ?? []),
      );
}

/// Gravedad más alta marcada en cada pieza, para pintarla.
Map<String, int> gravedadPorZona(List<Dano> danos) {
  final out = <String, int>{};
  for (final d in danos) {
    out[d.zona] = max(out[d.zona] ?? 0, d.sev);
  }
  return out;
}

/// Al cambiar el tipo de vehículo, los números se mueven al centro de su pieza
/// en el dibujo nuevo (o quedan sin ubicar si esa pieza no existe).
void reubicar(List<Dano> danos, Mapa m) {
  for (final d in danos) {
    final c = m.centroDe(d.zona);
    d.x = c?.x ?? -1;
    d.y = c?.y ?? -1;
    if (m.nombres[d.zona] != null) d.pieza = m.nombres[d.zona]!;
  }
}
