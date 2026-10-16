import '../components/fecha_utils.dart';
import '../models/compra.dart';
import 'alacena_db.dart';

class ComprasDAO {
  /// Una compra genera un lote nuevo + registro en historial (transacción).
  /// El trigger trg_historial_ultima_tienda actualiza productos.ultima_tienda_id.
  static Future<int> registrarCompra({
    required int productoId,
    required int tiendaId,
    required int cantidad,
    required double precioUnitario,
    required DateTime fecha,
    required DateTime caducidad,
    bool alarma = true,
  }) async {
    final db = await AlacenaDB.database;
    return db.transaction((txn) async {
      final loteId = await txn.insert('lotes', {
        'producto_id': productoId,
        'cantidad': cantidad,
        'fecha_caducidad': FechaUtils.toDb(caducidad),
        'fecha_registro': FechaUtils.toDb(fecha),
        'alarma': alarma ? 1 : 0,
      });
      return txn.insert('historial_compras', {
        'producto_id': productoId,
        'tienda_id': tiendaId,
        'lote_id': loteId,
        'cantidad': cantidad,
        'precio_unitario': precioUnitario,
        'fecha': FechaUtils.toDb(fecha),
      });
    });
  }

  static Future<List<Compra>> deProducto(int productoId) async {
    final db = await AlacenaDB.database;
    final r = await db.rawQuery('''
      SELECT h.*, t.nombre AS tienda
      FROM historial_compras h JOIN tiendas t ON t.id = h.tienda_id
      WHERE h.producto_id = ? ORDER BY h.fecha DESC, h.id DESC''', [productoId]);
    return r.map(Compra.fromMap).toList();
  }

  /// Histórico global: todas las tiendas donde se ha comprado el producto
  static Future<List<Map<String, Object?>>> tiendasDeProducto(int productoId) async {
    final db = await AlacenaDB.database;
    return db.rawQuery('''
      SELECT t.id, t.nombre, COUNT(h.id) AS compras, MAX(h.fecha) AS ultima_fecha,
             SUM(h.cantidad) AS unidades
      FROM historial_compras h JOIN tiendas t ON t.id = h.tienda_id
      WHERE h.producto_id = ?
      GROUP BY t.id, t.nombre ORDER BY ultima_fecha DESC''', [productoId]);
  }

  static Future<int> eliminar(int id) async => (await AlacenaDB.database)
      .delete('historial_compras', where: 'id = ?', whereArgs: [id]);
}
