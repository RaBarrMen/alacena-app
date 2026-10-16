import 'package:flutter/material.dart';

import '../components/dialogos.dart';
import '../components/global_values.dart';
import '../components/product_image.dart';
import '../database/carrito_dao.dart';
import '../models/carrito_item.dart';
import 'purchase_form_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CarritoItem> _items = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final items = await CarritoDAO.items();
    await GlobalValues.actualizarCarrito();
    if (mounted) setState(() => _items = items);
  }

  Future<void> _cantidad(CarritoItem i, int nueva) async {
    await CarritoDAO.cambiarCantidad(i.id, nueva);
    _cargar();
  }

  Future<void> _comprar(CarritoItem i) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PurchaseFormScreen(productoId: i.productoId, cantidadInicial: i.cantidad),
      ),
    );
    if (ok == true) {
      await CarritoDAO.eliminar(i.id);
      _cargar();
    }
  }

  Future<void> _vaciar() async {
    if (!await confirmar(context, 'Vaciar carrito', '¿Quitar todos los artículos?')) return;
    await CarritoDAO.vaciar();
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito de compra'),
        actions: [
          if (_items.isNotEmpty)
            IconButton(tooltip: 'Vaciar', onPressed: _vaciar, icon: const Icon(Icons.delete_sweep)),
        ],
      ),
      body: _items.isEmpty
          ? const Center(child: Text('Tu lista de compra está vacía'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _items.length,
              itemBuilder: (_, idx) {
                final i = _items[idx];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(children: [
                      ProductImage(ruta: i.imagen, size: 52),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(i.nombre, style: Theme.of(context).textTheme.titleMedium),
                          Row(children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _cantidad(i, i.cantidad - 1),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text('${i.cantidad} ${i.unidad}'),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _cantidad(i, i.cantidad + 1),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ]),
                        ]),
                      ),
                      IconButton(
                        tooltip: 'Registrar compra',
                        onPressed: () => _comprar(i),
                        icon: const Icon(Icons.shopping_bag_outlined),
                      ),
                      IconButton(
                        tooltip: 'Quitar',
                        onPressed: () async {
                          await CarritoDAO.eliminar(i.id);
                          _cargar();
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ]),
                  ),
                );
              },
            ),
    );
  }
}
