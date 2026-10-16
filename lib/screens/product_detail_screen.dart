import 'package:flutter/material.dart';

import '../components/dialogos.dart';
import '../components/fecha_utils.dart';
import '../components/global_values.dart';
import '../components/product_image.dart';
import '../components/status_chip.dart';
import '../database/carrito_dao.dart';
import '../database/compras_dao.dart';
import '../database/lotes_dao.dart';
import '../database/productos_dao.dart';
import '../models/compra.dart';
import '../models/lote.dart';
import '../models/producto.dart';
import 'product_form_screen.dart';
import 'purchase_form_screen.dart';

/// Detalle: lotes (FEFO), historial de compras y tiendas donde se ha comprado
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productoId});
  final int productoId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  ProductoResumen? _item;
  List<Lote> _lotes = [];
  List<Compra> _compras = [];
  List<Map<String, Object?>> _tiendas = [];
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
    final id = widget.productoId;
    final item = await ProductosDAO.porId(id);
    final lotes = await LotesDAO.deProducto(id);
    final compras = await ComprasDAO.deProducto(id);
    final tiendas = await ComprasDAO.tiendasDeProducto(id);
    if (!mounted) return;
    setState(() {
      _item = item;
      _lotes = lotes;
      _compras = compras;
      _tiendas = tiendas;
      _cargando = false;
    });
  }

  Future<void> _consumir() async {
    final ctrl = TextEditingController(text: '1');
    final n = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Consumir (FEFO)'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Disponible: ${_item!.stock} ${_item!.producto.unidad}. '
              'Se descuenta primero del lote que caduca antes.'),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Cantidad a consumir'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(ctrl.text)),
            child: const Text('Consumir'),
          ),
        ],
      ),
    );
    if (n == null) return;
    try {
      await LotesDAO.consumirFEFO(widget.productoId, n);
      await GlobalValues.inventarioCambio();
      if (mounted) avisar(context, 'Se consumieron $n');
    } catch (e) {
      if (mounted) avisar(context, mensajeError(e));
    }
  }

  Future<void> _registrarCompra() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PurchaseFormScreen(productoId: widget.productoId)),
      );

  Future<void> _editarLote(Lote l) async {
    final ctrl = TextEditingController(text: '${l.cantidad}');
    var fecha = l.fechaCaducidad;
    var alarma = l.alarma;
    final guardar = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Editar lote'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cantidad'),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text('Caduca: ${FechaUtils.corta(fecha)}'),
              onTap: () async {
                final f = await showDatePicker(
                  context: ctx,
                  initialDate: fecha,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035, 12, 31),
                );
                if (f != null) setD(() => fecha = f);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Alarma de caducidad'),
              value: alarma,
              onChanged: (v) => setD(() => alarma = v),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
          ],
        ),
      ),
    );
    if (guardar != true || !mounted) return;
    final cant = int.tryParse(ctrl.text);
    if (cant == null || cant < 0) {
      avisar(context, 'Cantidad inválida');
      return;
    }
    try {
      await LotesDAO.actualizar(l.copyWith(cantidad: cant, fechaCaducidad: fecha, alarma: alarma));
      await GlobalValues.inventarioCambio();
    } catch (e) {
      if (mounted) avisar(context, mensajeError(e));
    }
  }

  Future<void> _eliminarLote(Lote l) async {
    if (!await confirmar(context, 'Eliminar lote',
        '¿Eliminar el lote que caduca el ${FechaUtils.corta(l.fechaCaducidad)}?')) {
      return;
    }
    await LotesDAO.eliminar(l.id!);
    await GlobalValues.inventarioCambio();
  }

  Future<void> _eliminarCompra(Compra c) async {
    if (!await confirmar(context, 'Eliminar compra',
        '¿Eliminar el registro del historial? (el lote se conserva)')) {
      return;
    }
    await ComprasDAO.eliminar(c.id);
    await GlobalValues.inventarioCambio();
  }

  Future<void> _eliminarProducto() async {
    if (!await confirmar(context, 'Eliminar artículo',
        'Se eliminarán también sus lotes, historial de compras y carrito.')) {
      return;
    }
    try {
      await ProductosDAO.eliminar(widget.productoId);
      await GlobalValues.actualizarCarrito();
      await GlobalValues.inventarioCambio();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) avisar(context, mensajeError(e));
    }
  }

  Future<void> _agregarCarrito() async {
    await CarritoDAO.agregar(widget.productoId);
    await GlobalValues.actualizarCarrito();
    if (mounted) avisar(context, 'Agregado al carrito');
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final item = _item;
    if (item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Artículo no encontrado')),
      );
    }
    final p = item.producto;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(p.nombre),
          actions: [
            IconButton(
                tooltip: 'Agregar al carrito',
                onPressed: _agregarCarrito,
                icon: const Icon(Icons.add_shopping_cart)),
            IconButton(
              tooltip: 'Editar',
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => ProductFormScreen(producto: p))),
              icon: const Icon(Icons.edit),
            ),
            IconButton(
                tooltip: 'Eliminar',
                onPressed: _eliminarProducto,
                icon: const Icon(Icons.delete_outline)),
          ],
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ProductImage(ruta: p.imagen, size: 96),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  StatusChip(estatus: item.estatus),
                  const SizedBox(height: 6),
                  Text('Categoría: ${item.categoria}'),
                  Text('Stock total: ${item.stock} ${p.unidad} (mínimo ${p.stockMinimo})'),
                  if (item.proximaCaducidad != null)
                    Text(FechaUtils.textoCaducidad(item.proximaCaducidad!)),
                  Text('Última tienda: ${item.ultimaTienda ?? 'Sin compras'}'),
                  if (p.descripcion != null)
                    Text(p.descripcion!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall),
                ]),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: item.stock > 0 ? _consumir : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  label: const Text('Consumir'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _registrarCompra,
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('Registrar compra'),
                ),
              ),
            ]),
          ),
          const TabBar(tabs: [Tab(text: 'Lotes'), Tab(text: 'Compras'), Tab(text: 'Tiendas')]),
          Expanded(
            child: TabBarView(children: [_tabLotes(p), _tabCompras(p), _tabTiendas(p)]),
          ),
        ]),
      ),
    );
  }

  Widget _tabLotes(Producto p) {
    if (_lotes.isEmpty) {
      return const Center(child: Text('Sin lotes. Registra una compra.'));
    }
    return ListView(children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Text('Orden FEFO: se consume primero el de arriba.'),
      ),
      for (final l in _lotes)
        Builder(builder: (context) {
          final dias = FechaUtils.diasHasta(l.fechaCaducidad);
          final color = !l.activo
              ? Colors.grey
              : dias < 0
                  ? Estatus.caducado.color
                  : dias <= p.diasAlerta
                      ? Estatus.porCaducar.color
                      : Estatus.ok.color;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Text('${l.cantidad}', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ),
            title: Text('Caduca: ${FechaUtils.corta(l.fechaCaducidad)}'),
            subtitle: Text(l.activo ? FechaUtils.textoCaducidad(l.fechaCaducidad) : 'Lote consumido'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(l.alarma ? Icons.alarm_on : Icons.alarm_off, size: 20),
              PopupMenuButton<String>(
                onSelected: (v) => v == 'editar' ? _editarLote(l) : _eliminarLote(l),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'editar', child: Text('Editar')),
                  PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                ],
              ),
            ]),
          );
        }),
    ]);
  }

  Widget _tabCompras(Producto p) {
    if (_compras.isEmpty) return const Center(child: Text('Sin compras registradas'));
    return ListView(children: [
      for (final c in _compras)
        ListTile(
          leading: const Icon(Icons.receipt_long),
          title: Text('${c.cantidad} ${p.unidad} · ${c.tienda}'),
          subtitle: Text('${FechaUtils.corta(c.fecha)} · '
              '\$${c.precioUnitario.toStringAsFixed(2)} c/u · Total \$${c.total.toStringAsFixed(2)}'),
          trailing: IconButton(
            onPressed: () => _eliminarCompra(c),
            icon: const Icon(Icons.delete_outline),
          ),
        ),
    ]);
  }

  Widget _tabTiendas(Producto p) {
    if (_tiendas.isEmpty) return const Center(child: Text('Aún no se ha comprado en ninguna tienda'));
    return ListView(children: [
      for (final t in _tiendas)
        ListTile(
          leading: const Icon(Icons.storefront_outlined),
          title: Text(t['nombre'] as String),
          subtitle: Text('Compras: ${t['compras']} · Unidades: ${t['unidades']} · '
              'Última: ${FechaUtils.corta(FechaUtils.fromDb(t['ultima_fecha'] as String))}'),
          trailing: t['id'] == p.ultimaTiendaId ? const Chip(label: Text('Última')) : null,
        ),
    ]);
  }
}
