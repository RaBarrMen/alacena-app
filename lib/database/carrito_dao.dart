import 'package:sqflite/sqflite.dart';

import '../models/carrito_item.dart';
import 'alacena_db.dart';

class CarritoDAO {
  static Future<void> agregar(int productoId, {int cantidad = 1}) async {
    final db = await AlacenaDB.database;
    await db.transaction((txn) async {
      final n = await txn.rawUpdate(
          'UPDATE carrito SET cantidad = cantidad + ? WHERE producto_id = ?',
          [cantidad, productoId]);
      if (n == 0) {
        await txn.insert('carrito', {'producto_id': productoId, 'cantidad': cantidad});
      }
    });
  }

  static Future<List<CarritoItem>> items() async {
    final db = await AlacenaDB.database;
    final r = await db.rawQuery('''
      SELECT ca.id, ca.producto_id, ca.cantidad, p.nombre, p.imagen, p.unidad
      FROM carrito ca JOIN productos p ON p.id = ca.producto_id
      ORDER BY p.nombre COLLATE NOCASE''');
    return r.map(CarritoItem.fromMap).toList();
  }

  static Future<int> total() async {
    final db = await AlacenaDB.database;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM carrito')) ?? 0;
  }

  static Future<void> cambiarCantidad(int id, int cantidad) async {
    if (cantidad <= 0) return eliminar(id);
    final db = await AlacenaDB.database;
    await db.update('carrito', {'cantidad': cantidad}, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> eliminar(int id) async =>
      (await AlacenaDB.database).delete('carrito', where: 'id = ?', whereArgs: [id]);

  static Future<void> vaciar() async => (await AlacenaDB.database).delete('carrito');
}
