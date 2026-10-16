import 'package:flutter/material.dart';

import '../components/fecha_utils.dart';
import '../components/producto_tile.dart';
import '../components/status_chip.dart';
import '../models/producto.dart';
import 'product_detail_screen.dart';

/// Modal que cubre toda la pantalla con los artículos de un día
class DayModal extends StatelessWidget {
  const DayModal({super.key, required this.fecha, required this.productos});
  final DateTime fecha;
  final List<ProductoResumen> productos;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Artículos del día'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(28),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(FechaUtils.larga(fecha)),
            ),
          ),
        ),
        body: productos.isEmpty
            ? const Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.event_available, size: 64),
                  SizedBox(height: 8),
                  Text('Sin artículos con alerta este día'),
                ]),
              )
            : ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  child: LeyendaEstatus(conteo: ProductoResumen.contar(productos)),
                ),
                for (final p in productos)
                  ProductoTile(
                    item: p,
                    detallado: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(productoId: p.producto.id!)),
                    ),
                  ),
              ]),
      ),
    );
  }
}
