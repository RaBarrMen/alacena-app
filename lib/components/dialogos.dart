import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

Future<bool> confirmar(BuildContext context, String titulo, String mensaje) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Aceptar')),
      ],
    ),
  );
  return r ?? false;
}

void avisar(BuildContext context, String mensaje) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(mensaje)));
}

/// Traduce errores de integridad de SQLite a mensajes para el usuario
String mensajeError(Object e) {
  if (e is DatabaseException) {
    if (e.isUniqueConstraintError()) return 'Ya existe un registro con ese nombre.';
    final s = e.toString();
    if (s.contains('FOREIGN KEY')) return 'Operación no permitida: existen registros relacionados.';
    if (s.contains('CHECK')) return 'Algún dato no cumple las reglas de validación.';
    if (s.contains('NOT NULL')) return 'Faltan datos obligatorios.';
  }
  if (e is StateError) return e.message;
  if (e is ArgumentError) return '${e.message}';
  return 'Error: $e';
}

Future<String?> pedirTexto(BuildContext context, String titulo,
    {String inicial = '', String etiqueta = 'Nombre'}) async {
  final ctrl = TextEditingController(text: inicial);
  final r = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: etiqueta),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Guardar')),
      ],
    ),
  );
  return (r == null || r.isEmpty) ? null : r;
}
