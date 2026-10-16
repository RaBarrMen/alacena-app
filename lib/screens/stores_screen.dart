import 'package:flutter/material.dart';

import '../components/dialogos.dart';
import '../components/global_values.dart';
import '../database/tiendas_dao.dart';
import '../models/tienda.dart';

class StoresScreen extends StatefulWidget {
  const StoresScreen({super.key});

  @override
  State<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends State<StoresScreen> {
  List<(Tienda, int)> _items = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final r = await TiendasDAO.conConteo();
    if (mounted) setState(() => _items = r);
  }

  Future<void> _guardar([Tienda? t]) async {
    final nombre = TextEditingController(text: t?.nombre ?? '');
    final dir = TextEditingController(text: t?.direccion ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t == null ? 'Nueva tienda' : 'Editar tienda'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: nombre,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nombre *'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: dir,
            decoration: const InputDecoration(labelText: 'Dirección (opcional)'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (ok != true || nombre.text.trim().isEmpty) return;
    final tienda = Tienda(
      id: t?.id,
      nombre: nombre.text.trim(),
      direccion: dir.text.trim().isEmpty ? null : dir.text.trim(),
    );
    try {
      if (t == null) {
        await TiendasDAO.insertar(tienda);
      } else {
        await TiendasDAO.actualizar(tienda);
      }
      await GlobalValues.inventarioCambio();
    } catch (e) {
      if (mounted) avisar(context, mensajeError(e));
    }
    _cargar();
  }

  Future<void> _eliminar(Tienda t, int compras) async {
    // Integridad referencial: historial_compras.tienda_id ON DELETE RESTRICT
    if (compras > 0) {
      avisar(context, 'No se puede eliminar: tiene $compras compra(s) en el historial.');
      return;
    }
    if (!await confirmar(context, 'Eliminar tienda', '¿Eliminar "${t.nombre}"?')) return;
    try {
      await TiendasDAO.eliminar(t.id!);
      await GlobalValues.inventarioCambio();
    } catch (e) {
      if (mounted) avisar(context, mensajeError(e));
    }
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tiendas')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _guardar(),
        child: const Icon(Icons.add),
      ),
      body: _items.isEmpty
          ? const Center(child: Text('Sin tiendas'))
          : ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final (t, n) = _items[i];
                return ListTile(
                  leading: const Icon(Icons.storefront_outlined),
                  title: Text(t.nombre),
                  subtitle: Text([if (t.direccion != null) t.direccion!, '$n compra(s)'].join(' · ')),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(onPressed: () => _guardar(t), icon: const Icon(Icons.edit)),
                    IconButton(
                        onPressed: () => _eliminar(t, n), icon: const Icon(Icons.delete_outline)),
                  ]),
                );
              },
            ),
    );
  }
}
