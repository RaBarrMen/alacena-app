import 'package:flutter/material.dart';

import '../components/global_values.dart';
import '../components/producto_tile.dart';
import '../database/productos_dao.dart';
import '../models/producto.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart';

/// CRUD de artículos (listado completo)
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<ProductoResumen> _todos = [];
  String _filtro = '';

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
    final r = await ProductosDAO.resumen();
    if (mounted) setState(() => _todos = r);
  }

  @override
  Widget build(BuildContext context) {
    final f = _filtro.toLowerCase();
    final lista = _todos
        .where((p) =>
            p.producto.nombre.toLowerCase().contains(f) || p.categoria.toLowerCase().contains(f))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Artículos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const ProductFormScreen())),
        child: const Icon(Icons.add),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search), hintText: 'Buscar por nombre o categoría'),
            onChanged: (v) => setState(() => _filtro = v),
          ),
        ),
        Expanded(
          child: lista.isEmpty
              ? const Center(child: Text('Sin artículos'))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: lista.length,
                  itemBuilder: (_, i) => ProductoTile(
                    item: lista[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(productoId: lista[i].producto.id!)),
                    ),
                  ),
                ),
        ),
      ]),
    );
  }
}
