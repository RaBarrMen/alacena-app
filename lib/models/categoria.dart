class Categoria {
  final int? id;
  final String nombre;

  const Categoria({this.id, required this.nombre});

  factory Categoria.fromMap(Map<String, Object?> m) =>
      Categoria(id: m['id'] as int?, nombre: m['nombre'] as String);

  Map<String, Object?> toMap() => {'nombre': nombre.trim()};
}
