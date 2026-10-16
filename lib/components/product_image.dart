import 'dart:io';

import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({super.key, this.ruta, this.size = 56});
  final String? ruta;
  final double size;

  @override
  Widget build(BuildContext context) {
    final r = ruta;
    final existe = r != null && r.isNotEmpty && File(r).existsSync();
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: size,
        height: size,
        child: existe
            ? Image.file(File(r!), fit: BoxFit.cover)
            : Container(
                color: cs.surfaceContainerHighest,
                child: Icon(Icons.inventory_2_outlined,
                    size: size * 0.5, color: cs.onSurfaceVariant),
              ),
      ),
    );
  }
}
