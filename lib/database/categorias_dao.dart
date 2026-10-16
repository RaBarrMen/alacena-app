import '../models/categoria.dart';
import 'alacena_db.dart';

class CategoriasDAO {
  static Future<List<Categoria>> todas() async {
    final db = await AlacenaDB.database;
    final r = await db.query('categorias', orderBy: 'nombre COLLATE NOCASE');
    return r.map(Categoria.fromMap).toList();
  }

  /// (categoría, número de productos que la usan)
  static Future<List<(Categoria, int)>> conConteo() async {
    final db = await AlacenaDB.database;
    final r = await db.rawQuery('''
      SELECT c.id, c.nombre, COUNT(p.id) AS total
      FROM categorias c LEFT JOIN productos p ON p.categoria_id = c.id
      GROUP BY c.id, c.nombre ORDER BY c.nombre COLLATE NOCASE''');
    return r.map((m) => (Categoria.fromMap(m), m['total'] as int)).toList();
  }

  static Future<int> insertar(Categoria c) async =>
      (await AlacenaDB.database).insert('categorias', c.toMap());

  static Future<int> actualizar(Categoria c) async => (await AlacenaDB.database)
      .update('categorias', c.toMap(), where: 'id = ?', whereArgs: [c.id]);

  static Future<int> eliminar(int id) async => (await AlacenaDB.database)
      .delete('categorias', where: 'id = ?', whereArgs: [id]);
}
