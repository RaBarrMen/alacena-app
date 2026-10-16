import 'package:flutter/material.dart';

class ThemeApp {
  static ThemeData claro() => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2E7D6B),
        inputDecorationTheme:
            const InputDecorationTheme(border: OutlineInputBorder()),
      );
}
