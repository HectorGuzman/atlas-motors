import 'package:atlas_inspecciones/catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catálogo de marcas y modelos', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Catalog.load();
    expect(Catalog.marcas.length, greaterThan(100));
    expect(Catalog.buscar(Catalog.marcas, 'toy'), contains('Toyota'));
    expect(Catalog.buscar(Catalog.marcas, 'mercedes').first, 'Mercedes-Benz');
    expect(Catalog.buscar(Catalog.modelosDe('toyota'), 'hil').first, 'Hilux');
    expect(Catalog.buscar(Catalog.modelosDe('Honda'), 'crv'), contains('CR-V'));
    expect(Catalog.modelosDe('Marca inventada'), isEmpty);
    expect(Catalog.buscar(Catalog.marcas, '').length, 8);
  });
}
