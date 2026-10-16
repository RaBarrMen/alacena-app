import '../models/producto.dart';
import 'alacena_db.dart';

class ProductosDAO {
  /// Stock total = SUM(cantidad) de lotes activos (cantidad > 0)
  static const _base = '''
    SELECT p.*, c.nombre AS categoria, t.nombre AS ultima_tienda,
      COALESCE((SELECT SUM(l.cantidad) FROM lotes l
                WHERE l.producto_id = p.id AND l.cantidad > 0), 0) AS stock,
      (SELECT MIN(l.fecha_caducidad) FROM lotes l
        WHERE l.producto_id = p.id AND l.cantidad > 0) AS proxima_caducidad
    FROM productos p
    JOIN categorias c ON c.id = p.categoria_id
    LEFT JOIN tiendas t ON t.id = p.ultima_tienda_id''';

  static Future<List<ProductoResumen>> resumen() async {
    final db = await AlacenaDB.database;
    final r = await db.rawQuery('$_base ORDER BY p.nombre COLLATE NOCASE');
    return r.map(ProductoResumen.fromMap).toList();
  }

  /// Caducados, sin existencia, por caducar o por agotarse
  static Future<List<ProductoResumen>> conAlerta() async {
    final lista = (await resumen()).where((e) => e.estatus != Estatus.ok).toList();
    lista.sort((a, b) {
      final c = a.estatus.index.compareTo(b.estatus.index);
      return c != 0 ? c : a.fechaAlerta.compareTo(b.fechaAlerta);
    });
    return lista;
  }

  static Future<ProductoResumen?> porId(int id) async {
    final db = await AlacenaDB.database;
    final r = await db.rawQuery('$_base WHERE p.id = ?', [id]);
    return r.isEmpty ? null : ProductoResumen.fromMap(r.first);
  }

  static Future<int> insertar(Producto p) async =>
      (await AlacenaDB.database).insert('productos', p.toMap());

  static Future<int> actualizar(Producto p) async => (await AlacenaDB.database)
      .update('productos', p.toMap(), where: 'id = ?', whereArgs: [p.id]);

  /// CASCADE elimina sus lotes, historial y carrito
  static Future<int> eliminar(int id) async => (await AlacenaDB.database)
      .delete('productos', where: 'id = ?', whereArgs: [id]);
}
