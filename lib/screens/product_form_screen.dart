import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../components/dialogos.dart';
import '../components/global_values.dart';
import '../components/product_image.dart';
import '../database/categorias_dao.dart';
import '../database/productos_dao.dart';
import '../models/categoria.dart';
import '../models/producto.dart';
import 'product_detail_screen.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.producto});
  final Producto? producto;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.producto?.nombre ?? '');
  late final _desc = TextEditingController(text: widget.producto?.descripcion ?? '');
  late final _minimo = TextEditingController(text: '${widget.producto?.stockMinimo ?? 1}');
  late final _dias = TextEditingController(text: '${widget.producto?.diasAlerta ?? 3}');
  List<Categoria> _categorias = [];
  int? _categoriaId;
  String _unidad = 'pza';
  String? _imagen;

  bool get _editando => widget.producto != null;

  @override
  void initState() {
    super.initState();
    _categoriaId = widget.producto?.categoriaId;
    _unidad = widget.producto?.unidad ?? 'pza';
    _imagen = widget.producto?.imagen;
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    final c = await CategoriasDAO.todas();
    if (mounted) setState(() => _categorias = c);
  }

  Future<void> _nuevaCategoria() async {
    final n = await pedirTexto(context, 'Nueva categoría');
    if (n == null) return;
    try {
      final id = await CategoriasDAO.insertar(Categoria(nombre: n));
      await _cargarCategorias();
      setState(() => _categoriaId = id);
    } catch (e) {
      if (mounted) avisar(context, mensajeError(e));
    }
  }

  Future<void> _elegirImagen() async {
    final fuente = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Cámara'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Galería'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          if (_imagen != null)
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Quitar imagen'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _imagen = null);
              },
            ),
        ]),
      ),
    );
    if (fuente == null) return;
    final x = await ImagePicker().pickImage(source: fuente, maxWidth: 800, imageQuality: 80);
    if (x == null) return;
    // Copia al directorio de la app para que la ruta guardada en BD sea permanente
    final dir = await getApplicationDocumentsDirectory();
    final destino = path.join(
        dir.path, 'art_${DateTime.now().millisecondsSinceEpoch}${path.extension(x.path)}');
    await File(x.path).copy(destino);
    if (mounted) setState(() => _imagen = destino);
  }

  String? _validarEntero(String? v, int min, int max) {
    final n = int.tryParse(v ?? '');
    if (n == null) return 'Número entero';
    if (n < min || n > max) return 'Entre $min y $max';
    return null;
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    final prod = Producto(
      id: widget.producto?.id,
      nombre: _nombre.text.trim(),
      descripcion: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
      categoriaId: _categoriaId!,
      unidad: _unidad,
      stockMinimo: int.parse(_minimo.text),
      diasAlerta: int.parse(_dias.text),
      imagen: _imagen,
      ultimaTiendaId: widget.producto?.ultimaTiendaId,
    );
    var id = prod.id ?? 0;
    try {
      if (_editando) {
        await ProductosDAO.actualizar(prod);
      } else {
        id = await ProductosDAO.insertar(prod);
      }
      await GlobalValues.inventarioCambio();
    } catch (e) {
      if (mounted) avisar(context, mensajeError(e));
      return;
    }
    if (!mounted) return;
    if (_editando) {
      Navigator.pop(context, true);
    } else {
      // Al crear, se pasa al detalle para registrar la primera compra (lote)
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => ProductDetailScreen(productoId: id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriaValida = _categorias.any((c) => c.id == _categoriaId);

    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar artículo' : 'Nuevo artículo')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Center(
            child: GestureDetector(
              onTap: _elegirImagen,
              child: Stack(clipBehavior: Clip.none, children: [
                ProductImage(ruta: _imagen, size: 120),
                const Positioned(
                  right: -6,
                  bottom: -6,
                  child: CircleAvatar(radius: 18, child: Icon(Icons.photo_camera, size: 18)),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: categoriaValida ? _categoriaId : null,
                decoration: const InputDecoration(labelText: 'Categoría *'),
                hint: Text(_categorias.isEmpty ? 'Agregue una categoría' : 'Seleccione'),
                items: [
                  for (final c in _categorias)
                    DropdownMenuItem(value: c.id, child: Text(c.nombre)),
                ],
                onChanged: (v) => setState(() => _categoriaId = v),
                validator: (v) => v == null ? 'Seleccione una categoría' : null,
              ),
            ),
            IconButton(
              tooltip: 'Nueva categoría',
              onPressed: _nuevaCategoria,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ]),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nombre,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Nombre *'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _desc,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Descripción / marca'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _unidad,
            decoration: const InputDecoration(labelText: 'Unidad'),
            items: [
              for (final u in Producto.unidades) DropdownMenuItem(value: u, child: Text(u)),
            ],
            onChanged: (v) => setState(() => _unidad = v ?? 'pza'),
          ),
          const SizedBox(height: 16),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: TextFormField(
                controller: _minimo,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Stock mínimo', helperText: 'Alerta "por agotarse"'),
                validator: (v) => _validarEntero(v, 0, 100000),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _dias,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Días de aviso', helperText: 'Antes de caducar'),
                validator: (v) => _validarEntero(v, 0, 365),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _guardar,
            icon: const Icon(Icons.save),
            label: const Text('Guardar'),
          ),
          if (!_editando)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Después de guardar podrás registrar la compra (tienda, cantidad y caducidad).',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ]),
      ),
    );
  }
}
