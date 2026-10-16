import 'package:flutter/material.dart';

import '../database/carrito_dao.dart';
import '../models/producto.dart';
import 'dialogos.dart';
import 'fecha_utils.dart';
import 'global_values.dart';
import 'product_image.dart';
import 'status_chip.dart';

class ProductoTile extends StatelessWidget {
  const ProductoTile({
    super.key,
    required this.item,
    this.onTap,
    this.detallado = false,
    this.botonCarrito = true,
  });

  final ProductoResumen item;
  final VoidCallback? onTap;
  final bool detallado;
  final bool botonCarrito;

  Future<void> _agregarCarrito(BuildContext context) async {
    await CarritoDAO.agregar(item.producto.id!);
    await GlobalValues.actualizarCarrito();
    if (context.mounted) avisar(context, '${item.producto.nombre} agregado al carrito');
  }

  @override
  Widget build(BuildContext context) {
    final e = item.estatus;
    final p = item.producto;
    final chico = Theme.of(context).textTheme.bodySmall;

    Widget linea(String t) =>
        Text(t, style: chico, maxLines: 1, overflow: TextOverflow.ellipsis);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: e.color, width: 1.2),
      ),
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(width: 6, color: e.color),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Center(child: ProductImage(ruta: p.imagen, size: 64)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(p.nombre,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    linea('${item.categoria} · Stock: ${item.stock} ${p.unidad}'),
                    if (item.proximaCaducidad != null)
                      linea(FechaUtils.textoCaducidad(item.proximaCaducidad!)),
                    if (detallado) ...[
                      linea('Mínimo: ${p.stockMinimo} · Aviso: ${p.diasAlerta} día(s) antes'),
                      linea('Última tienda: ${item.ultimaTienda ?? 'Sin compras'}'),
                      if (p.descripcion != null) linea(p.descripcion!),
                    ],
                    const SizedBox(height: 6),
                    StatusChip(estatus: e),
                  ],
                ),
              ),
            ),
            if (botonCarrito)
              Center(
                child: IconButton(
                  tooltip: 'Agregar al carrito',
                  icon: const Icon(Icons.add_shopping_cart),
                  onPressed: () => _agregarCarrito(context),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
