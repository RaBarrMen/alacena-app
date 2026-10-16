class CarritoItem {
  final int id;
  final int productoId;
  final int cantidad;
  final String nombre;
  final String? imagen;
  final String unidad;

  const CarritoItem({
    required this.id,
    required this.productoId,
    required this.cantidad,
    required this.nombre,
    this.imagen,
    required this.unidad,
  });

  factory CarritoItem.fromMap(Map<String, Object?> m) => CarritoItem(
        id: m['id'] as int,
        productoId: m['producto_id'] as int,
        cantidad: m['cantidad'] as int,
        nombre: m['nombre'] as String,
        imagen: m['imagen'] as String?,
        unidad: m['unidad'] as String,
      );
}
