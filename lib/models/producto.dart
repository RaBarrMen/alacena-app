import 'package:flutter/material.dart';

import '../components/fecha_utils.dart';

/// Orden = prioridad (el primero es el más grave)
enum Estatus { caducado, agotado, porCaducar, porAgotarse, ok }

extension EstatusInfo on Estatus {
  String get etiqueta => switch (this) {
        Estatus.caducado => 'Caducado',
        Estatus.agotado => 'Sin existencia',
        Estatus.porCaducar => 'Por caducar',
        Estatus.porAgotarse => 'Por agotarse',
        Estatus.ok => 'En orden',
      };

  Color get color => switch (this) {
        Estatus.caducado => const Color(0xFFC62828),
        Estatus.agotado => const Color(0xFF616161),
        Estatus.porCaducar => const Color(0xFFEF6C00),
        Estatus.porAgotarse => const Color(0xFF1565C0),
        Estatus.ok => const Color(0xFF2E7D32),
      };

  IconData get icono => switch (this) {
        Estatus.caducado => Icons.dangerous_outlined,
        Estatus.agotado => Icons.remove_shopping_cart_outlined,
        Estatus.porCaducar => Icons.hourglass_bottom,
        Estatus.porAgotarse => Icons.trending_down,
        Estatus.ok => Icons.check_circle_outline,
      };
}

class Producto {
  static const unidades = ['pza', 'kg', 'g', 'l', 'ml', 'paquete', 'lata', 'caja'];

  final int? id;
  final String nombre;
  final String? descripcion;
  final int categoriaId;
  final String unidad;
  final int stockMinimo;
  final int diasAlerta;
  final String? imagen;
  final int? ultimaTiendaId;

  const Producto({
    this.id,
    required this.nombre,
    this.descripcion,
    required this.categoriaId,
    this.unidad = 'pza',
    this.stockMinimo = 1,
    this.diasAlerta = 3,
    this.imagen,
    this.ultimaTiendaId,
  });

  factory Producto.fromMap(Map<String, Object?> m) => Producto(
        id: m['id'] as int?,
        nombre: m['nombre'] as String,
        descripcion: m['descripcion'] as String?,
        categoriaId: m['categoria_id'] as int,
        unidad: m['unidad'] as String,
        stockMinimo: m['stock_minimo'] as int,
        diasAlerta: m['dias_alerta'] as int,
        imagen: m['imagen'] as String?,
        ultimaTiendaId: m['ultima_tienda_id'] as int?,
      );

  /// ultima_tienda_id NO se incluye: lo mantiene el trigger de historial_compras
  Map<String, Object?> toMap() => {
        'nombre': nombre.trim(),
        'descripcion': descripcion,
        'categoria_id': categoriaId,
        'unidad': unidad,
        'stock_minimo': stockMinimo,
        'dias_alerta': diasAlerta,
        'imagen': imagen,
      };
}

/// Producto + datos calculados (stock total y caducidad más próxima de lotes activos)
class ProductoResumen {
  final Producto producto;
  final String categoria;
  final String? ultimaTienda;
  final int stock;
  final DateTime? proximaCaducidad;

  ProductoResumen.fromMap(Map<String, Object?> m)
      : producto = Producto.fromMap(m),
        categoria = m['categoria'] as String,
        ultimaTienda = m['ultima_tienda'] as String?,
        stock = (m['stock'] as num? ?? 0).toInt(),
        proximaCaducidad = m['proxima_caducidad'] == null
            ? null
            : FechaUtils.fromDb(m['proxima_caducidad'] as String);

  Estatus get estatus {
    final cad = proximaCaducidad;
    if (cad != null && FechaUtils.diasHasta(cad) < 0) return Estatus.caducado;
    if (stock <= 0) return Estatus.agotado; // stock 0 o sin lotes
    if (cad != null && FechaUtils.diasHasta(cad) <= producto.diasAlerta) {
      return Estatus.porCaducar;
    }
    if (stock <= producto.stockMinimo) return Estatus.porAgotarse;
    return Estatus.ok;
  }

  /// Día en que se coloca la alerta en el calendario
  DateTime get fechaAlerta =>
      (estatus == Estatus.caducado || estatus == Estatus.porCaducar)
          ? proximaCaducidad!
          : FechaUtils.hoy;

  static Map<Estatus, int> contar(Iterable<ProductoResumen> lista) {
    final m = <Estatus, int>{};
    for (final p in lista) {
      m[p.estatus] = (m[p.estatus] ?? 0) + 1;
    }
    return m;
  }
}
