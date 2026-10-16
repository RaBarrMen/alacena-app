import '../components/fecha_utils.dart';

class Lote {
  final int? id;
  final int productoId;
  final int cantidad;
  final DateTime fechaCaducidad;
  final DateTime? fechaRegistro;
  final bool alarma; // campo para lanzar la alarma local el día de caducidad

  const Lote({
    this.id,
    required this.productoId,
    required this.cantidad,
    required this.fechaCaducidad,
    this.fechaRegistro,
    this.alarma = true,
  });

  bool get activo => cantidad > 0;

  factory Lote.fromMap(Map<String, Object?> m) => Lote(
        id: m['id'] as int?,
        productoId: m['producto_id'] as int,
        cantidad: m['cantidad'] as int,
        fechaCaducidad: FechaUtils.fromDb(m['fecha_caducidad'] as String),
        fechaRegistro: m['fecha_registro'] == null
            ? null
            : FechaUtils.fromDb(m['fecha_registro'] as String),
        alarma: (m['alarma'] as int) == 1,
      );

  Map<String, Object?> toMap() => {
        'producto_id': productoId,
        'cantidad': cantidad,
        'fecha_caducidad': FechaUtils.toDb(fechaCaducidad),
        'alarma': alarma ? 1 : 0,
      };

  Lote copyWith({int? cantidad, DateTime? fechaCaducidad, bool? alarma}) => Lote(
        id: id,
        productoId: productoId,
        cantidad: cantidad ?? this.cantidad,
        fechaCaducidad: fechaCaducidad ?? this.fechaCaducidad,
        fechaRegistro: fechaRegistro,
        alarma: alarma ?? this.alarma,
      );
}
