import 'package:flutter/material.dart';

import '../components/dialogos.dart';
import '../components/global_values.dart';
import '../database/categorias_dao.dart';
import '../models/categoria.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<(Categoria, int)> _items = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final r = await CategoriasDAO.conConteo();
    if (mounted) setState(() => _items = r);
  }

  Future<void> _guardar([Categoria? c]) async {
    final nombre = await pedirTexto(
        context, c == null ? 'Nueva categoría' : 'Editar categoría',
        inicial: c?.nombre ?? '');
    if (nombre == null) return;
    try {
      if (c == null) {
        await CategoriasDAO.insertar(Categoria(nombre: nombre));
      } else {
        await CategoriasDAO.actualizar(Categoria(id: c.id, nombre: nombre));
      }
      await GlobalValues.inventarioCambio();
    } catch (e) {
      if (mounted) avisar(context, mensajeError(e));
    }
    _cargar();
  }

  Future<void> _eliminar(Categoria c, int productos) async {
    // Integridad referencial: ON DELETE RESTRICT
    if (productos > 0) {
      avisar(context, 'No se puede eliminar: tiene $productos artículo(s).');
      return;
    }
    if (!await confirmar(context, 'Eliminar categoría', '¿Eliminar "${c.nombre}"?')) return;
    try {
      await CategoriasDAO.eliminar(c.id!);
    } catch (e) {
      if (mounted) avisar(context, mensajeError(e));
    }
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _guardar(),
        child: const Icon(Icons.add),
      ),
      body: _items.isEmpty
          ? const Center(child: Text('Sin categorías'))
          : ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final (c, n) = _items[i];
                return ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: Text(c.nombre),
                  subtitle: Text('$n artículo(s)'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(onPressed: () => _guardar(c), icon: const Icon(Icons.edit)),
                    IconButton(
                        onPressed: () => _eliminar(c, n), icon: const Icon(Icons.delete_outline)),
                  ]),
                );
              },
            ),
    );
  }
}
