import '../components/fecha_utils.dart';
import '../models/lote.dart';
import 'alacena_db.dart';

class LotesDAO {
  static Future<List<Lote>> deProducto(int productoId) async {
    final db = await AlacenaDB.database;
    final r = await db.query('lotes',
        where: 'producto_id = ?',
        whereArgs: [productoId],
        orderBy: 'CASE WHEN cantidad > 0 THEN 0 ELSE 1 END, fecha_caducidad, id');
    return r.map(Lote.fromMap).toList();
  }

  static Future<int> actualizar(Lote l) async => (await AlacenaDB.database)
      .update('lotes', l.toMap(), where: 'id = ?', whereArgs: [l.id]);

  static Future<int> eliminar(int id) async => (await AlacenaDB.database)
      .delete('lotes', where: 'id = ?', whereArgs: [id]);

  /// Regla FEFO: descuenta primero del lote con caducidad más próxima
  static Future<void> consumirFEFO(int productoId, int cantidad) async {
    if (cantidad <= 0) throw ArgumentError('La cantidad debe ser mayor a 0');
    final db = await AlacenaDB.database;
    await db.transaction((txn) async {
      final lotes = await txn.query('lotes',
          where: 'producto_id = ? AND cantidad > 0',
          whereArgs: [productoId],
          orderBy: 'fecha_caducidad ASC, id ASC');
      final disponible = lotes.fold<int>(0, (s, l) => s + (l['cantidad'] as int));
      if (cantidad > disponible) {
        throw StateError('Stock insuficiente (disponible: $disponible)');
      }
      var restante = cantidad;
      for (final l in lotes) {
        if (restante == 0) break;
        final actual = l['cantidad'] as int;
        final descuento = actual < restante ? actual : restante;
        await txn.update('lotes', {'cantidad': actual - descuento},
            where: 'id = ?', whereArgs: [l['id']]);
        restante -= descuento;
      }
    });
  }

  /// Lotes con existencia que caducan en una fecha
  static Future<List<Map<String, Object?>>> caducanEl(DateTime fecha) async {
    final db = await AlacenaDB.database;
    return db.rawQuery('''
      SELECT l.id AS lote_id, l.cantidad, l.alarma, p.id AS producto_id,
             p.nombre, p.imagen, p.unidad, c.nombre AS categoria
      FROM lotes l
      JOIN productos p ON p.id = l.producto_id
      JOIN categorias c ON c.id = p.categoria_id
      WHERE l.fecha_caducidad = ? AND l.cantidad > 0
      ORDER BY p.nombre COLLATE NOCASE''', [FechaUtils.toDb(fecha)]);
  }

  /// (fecha, nº de productos) de lotes con alarma activa, de hoy en adelante
  static Future<List<(DateTime, int)>> alarmasPendientes() async {
    final db = await AlacenaDB.database;
    final r = await db.rawQuery('''
      SELECT fecha_caducidad AS fecha, COUNT(DISTINCT producto_id) AS total
      FROM lotes
      WHERE alarma = 1 AND cantidad > 0 AND fecha_caducidad >= ?
      GROUP BY fecha_caducidad ORDER BY fecha_caducidad LIMIT 60''',
        [FechaUtils.toDb(FechaUtils.hoy)]);
    return r
        .map((m) => (FechaUtils.fromDb(m['fecha'] as String), m['total'] as int))
        .toList();
  }
}
