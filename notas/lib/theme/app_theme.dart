import 'package:flutter/material.dart';

class AppTheme {
  // Lista de colores disponibles para la app
  static final List<ThemeColor> themeColors = [
    ThemeColor(name: 'Teal Cyan', color: const Color(0xFF009688)),
    ThemeColor(name: 'Ocean Blue', color: const Color(0xFF2196F3)),
    ThemeColor(name: 'Sunset Coral', color: const Color(0xFFFF7043)),
    ThemeColor(name: 'Forest Green', color: const Color(0xFF4CAF50)),
    ThemeColor(name: 'Lavender', color: const Color(0xFF7E57C2)),
    ThemeColor(name: 'Sunrise Orange', color: const Color(0xFFFF9800)),
    ThemeColor(name: 'Rose Pink', color: const Color(0xFFEC407A)),
    ThemeColor(name: 'Slate Gray', color: const Color(0xFF607D8B)),
  ];

  // Obtener índice del color actual (por defecto Teal Cyan)
  static int getDefaultColorIndex() {
    return 0;
  }

  // Generar ThemeData con el color seleccionado
  static ThemeData getTheme(Color color) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: color,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}

class ThemeColor {
  final String name;
  final Color color;

  ThemeColor({required this.name, required this.color});
}
