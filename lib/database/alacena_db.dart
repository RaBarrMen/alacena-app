import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AlacenaDB {
  static const _nombre = 'alacena.db';
  static const _version = 1;
  static Database? _db;

  static Future<Database> get database async => _db ??= await _abrir();

  static Future<Database> _abrir() async {
    final ruta = join(await getDatabasesPath(), _nombre);
    return openDatabase(
      ruta,
      version: _version,
      // Integridad referencial: SQLite la trae apagada por defecto
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _crear,
    );
  }

  static Future<void> _crear(Database db, int version) async {
    final b = db.batch();

    b.execute('''
      CREATE TABLE categorias(
        id     INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE COLLATE NOCASE
               CHECK(length(trim(nombre)) > 0)
      )''');

    b.execute('''
      CREATE TABLE tiendas(
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre    TEXT NOT NULL UNIQUE COLLATE NOCASE
                  CHECK(length(trim(nombre)) > 0),
        direccion TEXT
      )''');

    b.execute('''
      CREATE TABLE productos(
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre           TEXT NOT NULL CHECK(length(trim(nombre)) > 0),
        descripcion      TEXT,
        categoria_id     INTEGER NOT NULL
                         REFERENCES categorias(id) ON UPDATE CASCADE ON DELETE RESTRICT,
        unidad           TEXT NOT NULL DEFAULT 'pza'
                         CHECK(unidad IN ('pza','kg','g','l','ml','paquete','lata','caja')),
        stock_minimo     INTEGER NOT NULL DEFAULT 1 CHECK(stock_minimo >= 0),
        dias_alerta      INTEGER NOT NULL DEFAULT 3 CHECK(dias_alerta BETWEEN 0 AND 365),
        imagen           TEXT,
        ultima_tienda_id INTEGER
                         REFERENCES tiendas(id) ON UPDATE CASCADE ON DELETE SET NULL
      )''');

    // alarma: campo que habilita la notificación local el día de caducidad
    b.execute('''
      CREATE TABLE lotes(
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id     INTEGER NOT NULL
                        REFERENCES productos(id) ON UPDATE CASCADE ON DELETE CASCADE,
        cantidad        INTEGER NOT NULL CHECK(cantidad >= 0),
        fecha_caducidad TEXT NOT NULL CHECK(fecha_caducidad IS date(fecha_caducidad)),
        fecha_registro  TEXT NOT NULL DEFAULT (date('now','localtime'))
                        CHECK(fecha_registro IS date(fecha_registro)),
        alarma          INTEGER NOT NULL DEFAULT 1 CHECK(alarma IN (0,1))
      )''');
    b.execute('CREATE INDEX idx_lotes_fefo ON lotes(producto_id, fecha_caducidad)');

    b.execute('''
      CREATE TABLE historial_compras(
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id     INTEGER NOT NULL
                        REFERENCES productos(id) ON UPDATE CASCADE ON DELETE CASCADE,
        tienda_id       INTEGER NOT NULL
                        REFERENCES tiendas(id) ON UPDATE CASCADE ON DELETE RESTRICT,
        lote_id         INTEGER REFERENCES lotes(id) ON DELETE SET NULL,
        cantidad        INTEGER NOT NULL CHECK(cantidad > 0),
        precio_unitario REAL NOT NULL DEFAULT 0 CHECK(precio_unitario >= 0),
        fecha           TEXT NOT NULL CHECK(fecha IS date(fecha))
      )''');

    b.execute('''
      CREATE TABLE carrito(
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id INTEGER NOT NULL UNIQUE
                    REFERENCES productos(id) ON UPDATE CASCADE ON DELETE CASCADE,
        cantidad    INTEGER NOT NULL DEFAULT 1 CHECK(cantidad > 0)
      )''');

    // Regla de negocio: última compra -> actualiza productos.ultima_tienda_id
    b.execute('''
      CREATE TRIGGER trg_historial_ultima_tienda
      AFTER INSERT ON historial_compras
      BEGIN
        UPDATE productos SET ultima_tienda_id = NEW.tienda_id
        WHERE id = NEW.producto_id;
      END''');

    // Catálogos iniciales
    for (final c in [
      'Abarrotes', 'Lácteos', 'Carnes y embutidos', 'Frutas y verduras',
      'Bebidas', 'Limpieza', 'Higiene personal',
    ]) {
      b.insert('categorias', {'nombre': c});
    }
    for (final t in ['Walmart', 'Soriana', 'Bodega Aurrera', 'OXXO', 'Mercado']) {
      b.insert('tiendas', {'nombre': t});
    }

    await b.commit(noResult: true);
  }
}
