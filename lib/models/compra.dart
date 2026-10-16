import '../components/fecha_utils.dart';

class Compra {
  final int id;
  final int productoId;
  final int tiendaId;
  final int? loteId;
  final int cantidad;
  final double precioUnitario;
  final DateTime fecha;
  final String tienda;

  const Compra({
    required this.id,
    required this.productoId,
    required this.tiendaId,
    this.loteId,
    required this.cantidad,
    required this.precioUnitario,
    required this.fecha,
    required this.tienda,
  });

  double get total => cantidad * precioUnitario;

  factory Compra.fromMap(Map<String, Object?> m) => Compra(
        id: m['id'] as int,
        productoId: m['producto_id'] as int,
        tiendaId: m['tienda_id'] as int,
        loteId: m['lote_id'] as int?,
        cantidad: m['cantidad'] as int,
        precioUnitario: (m['precio_unitario'] as num).toDouble(),
        fecha: FechaUtils.fromDb(m['fecha'] as String),
        tienda: m['tienda'] as String,
      );
}
