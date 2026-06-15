import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database/database_helper.dart';
import 'screens/home_page.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;

  // Cargar preferencias guardadas
  final prefs = await SharedPreferences.getInstance();
  final colorIndex =
      prefs.getInt('colorIndex') ?? AppTheme.getDefaultColorIndex();

  // Obtener texto compartido si existe
  String? sharedText;
  try {
    final channel = MethodChannel('com.example.notas/share');
    sharedText = await channel.invokeMethod<String>('getSharedText');
  } catch (e) {
    // Si no hay texto compartido, continuar normal
    sharedText = null;
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(NotesApp(initialColorIndex: colorIndex, sharedText: sharedText));
}

class NotesApp extends StatefulWidget {
  final int initialColorIndex;
  final String? sharedText;

  const NotesApp({super.key, required this.initialColorIndex, this.sharedText});

  @override
  State<NotesApp> createState() => _NotesAppState();
}

class _NotesAppState extends State<NotesApp> {
  late int _currentColorIndex;
  String? _sharedText;

  @override
  void initState() {
    super.initState();
    _currentColorIndex = widget.initialColorIndex;
    _sharedText = widget.sharedText;
  }

  Future<void> _changeColor(int index) async {
    setState(() {
      _currentColorIndex = index;
    });
    // Guardar preferencia
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('colorIndex', index);
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = AppTheme.themeColors[_currentColorIndex].color;

    return MaterialApp(
      title: 'Notas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(currentColor),
      home: HomePage(
        currentColorIndex: _currentColorIndex,
        onColorChanged: _changeColor,
        sharedText: _sharedText,
        onSharedTextHandled: () {
          _sharedText = null;
        },
      ),
    );
  }
}
