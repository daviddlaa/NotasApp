import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

import 'database/database_helper.dart';
import 'screens/login_page.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp();

  await DatabaseHelper.instance.database;

  // Cargar preferencias guardadas
  final prefs = await SharedPreferences.getInstance();
  final colorIndex =
      prefs.getInt('colorIndex') ?? AppTheme.getDefaultColorIndex();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(NotesApp(initialColorIndex: colorIndex));
}

class NotesApp extends StatefulWidget {
  final int initialColorIndex;

  const NotesApp({super.key, required this.initialColorIndex});

  @override
  State<NotesApp> createState() => _NotesAppState();
}

class _NotesAppState extends State<NotesApp> {
  late int _currentColorIndex;

  @override
  void initState() {
    super.initState();
    _currentColorIndex = widget.initialColorIndex;
  }

  Future<void> _changeColor(int index) async {
    setState(() {
      _currentColorIndex = index;
    });
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
      home: LoginPage(
        currentColorIndex: _currentColorIndex,
        onColorChanged: _changeColor,
      ),
    );
  }
}
