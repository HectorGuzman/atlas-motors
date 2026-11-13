import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../catalog.dart';
import '../store.dart';
import '../theme.dart';

/// Datos del cliente y del vehículo. Sirve para crear y para editar.
class VehicleFormScreen extends StatefulWidget {
  final Inspection? inspection;
  const VehicleFormScreen({super.key, this.inspection});
  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> c;
  late DateTime _fecha;
  late int _modalidad = widget.inspection?.modalidad ?? 0;
  final _marcaFocus = FocusNode();
  final _modeloFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final i = widget.inspection;
    _fecha = i?.fecha ?? DateTime.now();
    c = {
      'marca': TextEditingController(text: i?.marca),
      'modelo': TextEditingController(text: i?.modelo),
      'anio': TextEditingController(text: i?.anio),
      'patente': TextEditingController(text: i?.patente),
      'km': TextEditingController(text: i?.km),
      'cliente': TextEditingController(text: i?.cliente),
      'telefono': TextEditingController(text: _soloNumero(i?.telefono ?? '')),
      'lugar': TextEditingController(text: i?.lugar),
    };
  }

  @override
  void dispose() {
    for (final t in c.values) {
      t.dispose();
    }
    _marcaFocus.dispose();
    _modeloFocus.dispose();
    super.dispose();
  }

  /// [comenzar] false = guardar para después y volver a la lista.
  Future<void> _save({bool comenzar = true}) async {
    if (!_form.currentState!.validate()) return;
    final i = widget.inspection ?? Store.I.create();
    i
      ..marca = c['marca']!.text.trim()
      ..modelo = c['modelo']!.text.trim()
      ..anio = c['anio']!.text.trim()
      ..patente = c['patente']!.text.trim().toUpperCase()
      ..km = c['km']!.text.trim()
      ..cliente = c['cliente']!.text.trim()
      ..telefono = _conPrefijo(c['telefono']!.text)
      ..lugar = c['lugar']!.text.trim()
      ..fecha = _fecha
      ..modalidad = _modalidad;
    await Store.I.save();
    if (!mounted) return;
    if (!comenzar) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${i.vehiculo} quedó guardada como pendiente.')));
    }
    Navigator.pop(context, comenzar ? i : null);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
        context: context, initialDate: _fecha, firstDate: DateTime(2024), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (d != null) setState(() => _fecha = d);
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null;

  /// Los 8 dígitos que van después del +56 9.
  static String _soloNumero(String tel) {
    var d = tel.replaceAll(RegExp(r'\D'), '');
    if (d.length > 8 && d.startsWith('569')) d = d.substring(3);
    return d.length > 8 ? d.substring(d.length - 8) : d;
  }

  static String _conPrefijo(String digitos) {
    final d = digitos.replaceAll(RegExp(r'\D'), '');
    if (d.isEmpty) return '';
    return d.length == 8 ? '+56 9 ${d.substring(0, 4)} ${d.substring(4)}' : '+56 9 $d';
  }

  Widget _telefono() => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c['telefono'],
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
          textInputAction: TextInputAction.next,
          validator: (v) => (v == null || v.isEmpty || v.length == 8) ? null : 'Deben ser 8 dígitos',
          decoration: const InputDecoration(
            labelText: 'Teléfono / WhatsApp',
            floatingLabelBehavior: FloatingLabelBehavior.always,
            prefixText: '+56 9  ',
            prefixStyle: TextStyle(color: C.text, fontWeight: FontWeight.w600, fontSize: 16),
            hintText: '1234 5678',
          ),
        ),
      );

  Widget _f(String key, String label,
          {bool required = false, TextInputType? type, TextCapitalization cap = TextCapitalization.words, List<TextInputFormatter>? fmt}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c[key],
          validator: required ? _req : null,
          keyboardType: type,
          textCapitalization: cap,
          inputFormatters: fmt,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: required ? '$label *' : label),
        ),
      );

  /// Campo con sugerencias del catálogo. Si el vehículo no está en la lista,
  /// se puede escribir libremente.
  Widget _auto(String key, String label, FocusNode focus, List<String> Function(String) opciones,
      {ValueChanged<String>? onSelected}) {
    return LayoutBuilder(
      builder: (context, box) => RawAutocomplete<String>(
        textEditingController: c[key],
        focusNode: focus,
        optionsBuilder: (v) => opciones(v.text),
        onSelected: onSelected,
        fieldViewBuilder: (context, controller, focusNode, onSubmit) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            validator: _req,
            autocorrect: false,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: '$label *'),
          ),
        ),
        optionsViewBuilder: (context, select, options) => Align(
          alignment: Alignment.topLeft,
          child: Transform.translate(
            offset: const Offset(0, -8),
            child: Material(
              elevation: 6,
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 232, maxWidth: box.maxWidth),
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: [
                    for (final o in options)
                      InkWell(
                        onTap: () => select(o),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                          child: Text(o, style: const TextStyle(fontSize: 15.5)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final digits = [FilteringTextInputFormatter.digitsOnly];
    return Scaffold(
      appBar: AppBar(title: Text(widget.inspection == null ? 'Nueva inspección' : 'Editar datos')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            Text('Vehículo', style: display(18)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _auto('marca', 'Marca', _marcaFocus, (t) => Catalog.buscar(Catalog.marcas, t),
                    onSelected: (_) => _modeloFocus.requestFocus()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _auto('modelo', 'Modelo', _modeloFocus,
                    (t) => Catalog.buscar(Catalog.modelosDe(c['marca']!.text), t)),
              ),
            ]),
            Row(children: [
              Expanded(child: _f('anio', 'Año', type: TextInputType.number, fmt: [...digits, LengthLimitingTextInputFormatter(4)])),
              const SizedBox(width: 12),
              Expanded(child: _f('patente', 'Patente', cap: TextCapitalization.characters)),
            ]),
            _f('km', 'Kilometraje', type: TextInputType.number, fmt: digits),
            const SizedBox(height: 12),
            Text('Cliente e inspección', style: display(18)),
            const SizedBox(height: 12),
            _f('cliente', 'Nombre del cliente'),
            _telefono(),
            _f('lugar', 'Lugar de la inspección'),
            const Text('¿El cliente estará presente?', style: TextStyle(color: C.muted, fontSize: 13.5)),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Sí, presencial'), icon: Icon(Icons.person_outline)),
                ButtonSegment(value: 1, label: Text('No, remota'), icon: Icon(Icons.videocam_outlined)),
              ],
              selected: {_modalidad},
              showSelectedIcon: false,
              onSelectionChanged: (v) => setState(() => _modalidad = v.first),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: C.green900,
                selectedForegroundColor: C.gold200,
                backgroundColor: Colors.white,
                side: const BorderSide(color: C.line),
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Fecha', suffixIcon: Icon(Icons.calendar_today_outlined)),
                child: Text(DateFormat("EEEE d 'de' MMMM 'de' y", 'es').format(_fecha)),
              ),
            ),
            const SizedBox(height: 28),
            GoldButton(widget.inspection == null ? 'Comenzar inspección' : 'Guardar cambios',
                icon: Icons.arrow_forward, onPressed: _save),
            if (widget.inspection == null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _save(comenzar: false),
                icon: const Icon(Icons.bookmark_add_outlined),
                label: const Text('Guardar para después'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: C.green900,
                  side: const BorderSide(color: C.green700, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
