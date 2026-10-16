import '../models/tienda.dart';
import 'alacena_db.dart';

class TiendasDAO {
  static Future<List<Tienda>> todas() async {
    final db = await AlacenaDB.database;
    final r = await db.query('tiendas', orderBy: 'nombre COLLATE NOCASE');
    return r.map(Tienda.fromMap).toList();
  }

  /// (tienda, número de compras registradas)
  static Future<List<(Tienda, int)>> conConteo() async {
    final db = await AlacenaDB.database;
    final r = await db.rawQuery('''
      SELECT t.id, t.nombre, t.direccion, COUNT(h.id) AS total
      FROM tiendas t LEFT JOIN historial_compras h ON h.tienda_id = t.id
      GROUP BY t.id, t.nombre, t.direccion ORDER BY t.nombre COLLATE NOCASE''');
    return r.map((m) => (Tienda.fromMap(m), m['total'] as int)).toList();
  }

  static Future<int> insertar(Tienda t) async =>
      (await AlacenaDB.database).insert('tiendas', t.toMap());

  static Future<int> actualizar(Tienda t) async => (await AlacenaDB.database)
      .update('tiendas', t.toMap(), where: 'id = ?', whereArgs: [t.id]);

  static Future<int> eliminar(int id) async => (await AlacenaDB.database)
      .delete('tiendas', where: 'id = ?', whereArgs: [id]);
}
