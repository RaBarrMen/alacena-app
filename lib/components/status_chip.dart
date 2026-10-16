import 'package:flutter/material.dart';

import '../models/producto.dart';

/// Identificación rápida del estatus: color + icono + texto
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.estatus, this.texto});
  final Estatus estatus;
  final String? texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: estatus.color.withValues(alpha: 0.12),
        border: Border.all(color: estatus.color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(estatus.icono, size: 14, color: estatus.color),
        const SizedBox(width: 4),
        Text(texto ?? estatus.etiqueta,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: estatus.color)),
      ]),
    );
  }
}

class LeyendaEstatus extends StatelessWidget {
  const LeyendaEstatus({super.key, this.conteo});
  final Map<Estatus, int>? conteo;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 6, runSpacing: 6, children: [
      for (final e in Estatus.values)
        if (e != Estatus.ok)
          StatusChip(
            estatus: e,
            texto: conteo == null ? null : '${e.etiqueta} (${conteo![e] ?? 0})',
          ),
    ]);
  }
}
