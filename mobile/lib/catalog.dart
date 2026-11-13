import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Marcas y modelos de vehículos livianos vendidos en Chile, sacados de la
/// nómina de tasación fiscal del SII (ver tool/sii_catalogo.py).
/// Viene dentro de la app, así que funciona sin señal.
class Catalog {
  static List<String> marcas = [];
  static final Map<String, List<String>> _modelos = {};

  static Future<void> load() async {
    final list = jsonDecode(await rootBundle.loadString('assets/catalogo.json')) as List;
    for (final e in list) {
      marcas.add(e['m']);
      _modelos[_norm(e['m'])] = List<String>.from(e['o']);
    }
  }

  static List<String> modelosDe(String marca) => _modelos[_norm(marca)] ?? const [];

  /// Sugerencias: primero las que empiezan con el texto, luego las que lo contienen.
  /// Las listas ya vienen ordenadas de más a menos común.
  static List<String> buscar(List<String> opciones, String texto, {int max = 8}) {
    final q = _norm(texto);
    if (q.isEmpty) return opciones.take(max).toList();
    final empieza = <String>[], contiene = <String>[];
    for (final o in opciones) {
      final n = _norm(o);
      if (o == texto.trim()) continue; // ya está escrito tal cual
      if (n.startsWith(q)) {
        empieza.add(o);
      } else if (n.contains(q)) {
        contiene.add(o);
      }
    }
    return [...empieza, ...contiene].take(max).toList();
  }

  static String _norm(String s) => s
      .toLowerCase()
      .trim()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll(RegExp(r'[\s\-]+'), '');
}
