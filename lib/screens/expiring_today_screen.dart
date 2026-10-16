import 'package:flutter/material.dart';

import '../components/fecha_utils.dart';
import '../components/global_values.dart';
import '../components/product_image.dart';
import '../database/lotes_dao.dart';
import '../models/producto.dart';
import 'product_detail_screen.dart';

/// Pantalla que abre la alarma local: productos que caducan ese día
class ExpiringTodayScreen extends StatefulWidget {
  const ExpiringTodayScreen({super.key, this.fecha});
  final DateTime? fecha;

  @override
  State<ExpiringTodayScreen> createState() => _ExpiringTodayScreenState();
}

class _ExpiringTodayScreenState extends State<ExpiringTodayScreen> {
  late DateTime _fecha = FechaUtils.soloFecha(widget.fecha ?? DateTime.now());
  List<Map<String, Object?>> _lotes = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
    GlobalValues.inventario.addListener(_cargar);
  }

  @override
  void dispose() {
    GlobalValues.inventario.removeListener(_cargar);
    super.dispose();
  }

  Future<void> _cargar() async {
    final r = await LotesDAO.caducanEl(_fecha);
    if (mounted) {
      setState(() {
        _lotes = r;
        _cargando = false;
      });
    }
  }

  Future<void> _cambiarFecha() async {
    final f = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035, 12, 31),
    );
    if (f == null) return;
    _fecha = f;
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final esHoy = FechaUtils.diasHasta(_fecha) == 0;
    final color = Estatus.caducado.color;

    return Scaffold(
      appBar: AppBar(
        title: Text(esHoy ? 'Caducan hoy' : 'Caducan ese día'),
        actions: [
          IconButton(onPressed: _cambiarFecha, icon: const Icon(Icons.edit_calendar)),
        ],
      ),
      body: Column(children: [
        Container(
          width: double.infinity,
          color: color.withValues(alpha: 0.1),
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Icon(Icons.alarm, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text('${FechaUtils.larga(_fecha)}\n'
                  '${_lotes.length} lote(s) caducan este día'),
            ),
          ]),
        ),
        Expanded(
          child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : _lotes.isEmpty
                  ? const Center(child: Text('Ningún artículo caduca este día'))
                  : ListView.builder(
                      itemCount: _lotes.length,
                      itemBuilder: (_, i) {
                        final l = _lotes[i];
                        return ListTile(
                          leading: ProductImage(ruta: l['imagen'] as String?, size: 48),
                          title: Text(l['nombre'] as String),
                          subtitle: Text('${l['cantidad']} ${l['unidad']} · ${l['categoria']}'),
                          trailing: Icon(Estatus.porCaducar.icono, color: Estatus.porCaducar.color),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductDetailScreen(productoId: l['producto_id'] as int),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ]),
    );
  }
}
