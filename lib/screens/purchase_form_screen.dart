import 'package:flutter/material.dart';

import '../components/dialogos.dart';
import '../components/fecha_utils.dart';
import '../components/global_values.dart';
import '../database/compras_dao.dart';
import '../database/productos_dao.dart';
import '../database/tiendas_dao.dart';
import '../models/tienda.dart';

/// Registrar compra = nuevo lote + historial_compras (+ trigger de última tienda)
class PurchaseFormScreen extends StatefulWidget {
  const PurchaseFormScreen({super.key, required this.productoId, this.cantidadInicial = 1});
  final int productoId;
  final int cantidadInicial;

  @override
  State<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends State<PurchaseFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _cantidad = TextEditingController(text: '${widget.cantidadInicial}');
  final _precio = TextEditingController(text: '0');
  List<Tienda> _tiendas = [];
  int? _tiendaId;
  String _nombre = '';
  String _unidad = '';
  DateTime _fechaCompra = FechaUtils.hoy;
  DateTime? _caducidad;
  bool _alarma = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final tiendas = await TiendasDAO.todas();
    final prod = await ProductosDAO.porId(widget.productoId);
    if (!mounted) return;
    setState(() {
      _tiendas = tiendas;
      _nombre = prod?.producto.nombre ?? '';
      _unidad = prod?.producto.unidad ?? '';
      _tiendaId ??= prod?.producto.ultimaTiendaId;
    });
  }

  Future<void> _nuevaTienda() async {
    final n = await pedirTexto(context, 'Nueva tienda');
    if (n == null) return;
    try {
      final id = await TiendasDAO.insertar(Tienda(nombre: n));
      final t = await TiendasDAO.todas();
      if (!mounted) return;
      setState(() {
        _tiendas = t;
        _tiendaId = id;
      });
    } catch (e) {
      if (mounted) avisar(context, mensajeError(e));
    }
  }

  Future<void> _elegirFecha({required bool caducidad}) async {
    final f = await showDatePicker(
      context: context,
      initialDate: caducidad
          ? (_caducidad ?? FechaUtils.hoy.add(const Duration(days: 7)))
          : _fechaCompra,
      firstDate: DateTime(2020),
      lastDate: caducidad ? DateTime(2035, 12, 31) : FechaUtils.hoy,
      helpText: caducidad ? 'Fecha de caducidad' : 'Fecha de compra',
    );
    if (f == null) return;
    setState(() {
      if (caducidad) {
        _caducidad = f;
      } else {
        _fechaCompra = f;
      }
    });
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    if (_caducidad == null) {
      avisar(context, 'Seleccione la fecha de caducidad');
      return;
    }
    setState(() => _guardando = true);
    try {
      await ComprasDAO.registrarCompra(
        productoId: widget.productoId,
        tiendaId: _tiendaId!,
        cantidad: int.parse(_cantidad.text),
        precioUnitario: double.parse(_precio.text.replaceAll(',', '.')),
        fecha: _fechaCompra,
        caducidad: _caducidad!,
        alarma: _alarma,
      );
      await GlobalValues.inventarioCambio();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      avisar(context, mensajeError(e));
      setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tiendaValida = _tiendas.any((t) => t.id == _tiendaId);

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar compra')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if (_nombre.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text('Artículo: $_nombre', style: Theme.of(context).textTheme.titleMedium),
            ),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: tiendaValida ? _tiendaId : null,
                decoration: const InputDecoration(labelText: 'Tienda *'),
                items: [
                  for (final t in _tiendas) DropdownMenuItem(value: t.id, child: Text(t.nombre)),
                ],
                onChanged: (v) => setState(() => _tiendaId = v),
                validator: (v) => v == null ? 'Seleccione la tienda' : null,
              ),
            ),
            IconButton(
              tooltip: 'Nueva tienda',
              onPressed: _nuevaTienda,
              icon: const Icon(Icons.add_business_outlined),
            ),
          ]),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cantidad,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Cantidad *', suffixText: _unidad),
            validator: (v) {
              final n = int.tryParse(v ?? '');
              return (n == null || n <= 0) ? 'Entero mayor a 0' : null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _precio,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Precio unitario', prefixText: '\$ '),
            validator: (v) {
              final n = double.tryParse((v ?? '').replaceAll(',', '.'));
              return (n == null || n < 0) ? 'Precio inválido' : null;
            },
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_note),
            title: const Text('Fecha de compra'),
            subtitle: Text(FechaUtils.corta(_fechaCompra)),
            onTap: () => _elegirFecha(caducidad: false),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_busy),
            title: const Text('Fecha de caducidad *'),
            subtitle: Text(_caducidad == null ? 'Seleccionar' : FechaUtils.corta(_caducidad!)),
            onTap: () => _elegirFecha(caducidad: true),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Alarma el día de caducidad'),
            subtitle: const Text('Notificación local a las 9:00'),
            value: _alarma,
            onChanged: (v) => setState(() => _alarma = v),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _guardando ? null : _guardar,
            icon: const Icon(Icons.save),
            label: const Text('Guardar compra'),
          ),
        ]),
      ),
    );
  }
}
