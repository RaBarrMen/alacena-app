class Tienda {
  final int? id;
  final String nombre;
  final String? direccion;

  const Tienda({this.id, required this.nombre, this.direccion});

  factory Tienda.fromMap(Map<String, Object?> m) => Tienda(
        id: m['id'] as int?,
        nombre: m['nombre'] as String,
        direccion: m['direccion'] as String?,
      );

  Map<String, Object?> toMap() => {'nombre': nombre.trim(), 'direccion': direccion};
}
