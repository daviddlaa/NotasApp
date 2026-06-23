import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/note.dart';

class NotePlayerPage extends StatefulWidget {
  final Note note;

  const NotePlayerPage({super.key, required this.note});

  @override
  State<NotePlayerPage> createState() => _NotePlayerPageState();
}

class _NotePlayerPageState extends State<NotePlayerPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isPlaying = true;

  // Tamaño de letra inicial y límites
  // IMPORTANTE: Siempre empieza con letra grande (tamaño máximo)
  late double _fontSize; // Se inicializa en initState usando _maxFontSize
  static const double _minFontSize = 20.0;
  late double _maxFontSize; // Se ajusta dinámicamente

  // Velocidad de scroll (1x, 2x, 3x)
  int _speed = 2; // Velocidad inicial 2x

  // Función para detectar emojis en el texto
  bool _hasEmojis(String text) {
    final emojiRegex = RegExp(
      r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E0}-\u{1F1FF}\u{2700}-\u{27BF}\u{1F900}-\u{1F9FF}\u{1F700}-\u{1F77F}\u{1F780}-\u{1F7FF}\u{1F800}-\u{1F8FF}]',
      unicode: true,
    );
    return emojiRegex.hasMatch(text);
  }

  @override
  void initState() {
    super.initState();
    // Forzar modo landscape - el teléfono se rota automáticamente
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Velocidad basada en longitud del texto (más lenta = más fácil de leer)
    // IMPORTANTE: La velocidad inicial es 2x
    final baseDuration = (widget.note.content.length / 10).ceil().clamp(10, 60);
    final durationSeconds = (baseDuration / 2)
        .round(); // Aplicar velocidad inicial 2x
    _controller = AnimationController(
      duration: Duration(seconds: durationSeconds.clamp(5, 60)),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 1.0,
      end: -2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    // Ajustar tamaño máximo según longitud del texto Y si hay emojis
    // Esto evita que el player falle con textos muy largos
    final contentLength = widget.note.content.length;
    double baseMaxFontSize = _hasEmojis(widget.note.content) ? 150.0 : 200.0;

    // Reducir tamaño según longitud del texto
    if (contentLength < 300) {
      _maxFontSize = baseMaxFontSize; // 150-200px para textos cortos
    } else if (contentLength < 500) {
      _maxFontSize = (baseMaxFontSize * 0.6).clamp(80.0, 120.0); // 80-120px
    } else if (contentLength < 800) {
      _maxFontSize = (baseMaxFontSize * 0.4).clamp(50.0, 80.0); // 50-80px
    } else {
      _maxFontSize = (baseMaxFontSize * 0.3).clamp(
        30.0,
        50.0,
      ); // 30-50px para textos muy largos
    }

    // IMPORTANTE: Siempre empieza con letra grande (tamaño máximo)
    _fontSize = _maxFontSize;

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    // Restaurar orientaciones
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    });
  }

  // Ajustar tamaño de letra con gesto vertical
  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      // Deslizar hacia arriba = letra más grande
      // Deslizar hacia abajo = letra más pequeña
      _fontSize = (_fontSize - details.delta.dy).clamp(
        _minFontSize,
        _maxFontSize,
      );
    });
  }

  // Cambiar velocidad de scroll
  void _setSpeed(int speed) {
    setState(() {
      _speed = speed;
      // Calcular nueva duración basada en multiplicador de velocidad
      final baseDuration = (widget.note.content.length / 10).ceil().clamp(
        10,
        60,
      );
      final newDurationSeconds = (baseDuration / speed).round();
      _controller.duration = Duration(seconds: newDurationSeconds.clamp(5, 60));
      // Reiniciar animación si está reproduciendo
      if (_isPlaying) {
        _controller.repeat();
      }
    });
  }

  // Construir botón de velocidad con emojis
  Widget _buildSpeedButton(int speed) {
    final isSelected = _speed == speed;
    // Emojis para cada velocidad: 1x=lento, 2x=normal, 3x=rápido
    final String speedEmoji;
    switch (speed) {
      case 1:
        speedEmoji = '🐢';
        break;
      case 2:
        speedEmoji = '🏃';
        break;
      case 3:
        speedEmoji = '🚀';
        break;
      default:
        speedEmoji = '${speed}x';
    }
    return GestureDetector(
      onTap: () => _setSpeed(speed),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white24,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.white38,
            width: 1,
          ),
        ),
        child: Text(
          speedEmoji,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Solo el contenido de la nota
    final fullText = ' ${widget.note.content} ';

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _togglePlayPause,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        child: Stack(
          children: [
            // Fondo negro total
            Container(color: Colors.black),

            // Línea de texto scrolling - ocupa toda la pantalla
            Center(
              child: SizedBox(
                height: screenHeight,
                width: double.infinity,
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Stack(
                      children: [
                        Positioned(
                          left: screenWidth * _animation.value,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Text(
                              fullText,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: _fontSize,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                                letterSpacing: 1,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // Indicador de estado (PLAY/PAUSE)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isPlaying ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _isPlaying ? 'PLAY' : 'PAUSE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Indicador de tamaño de letra
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Letra: ${_fontSize.toInt()}',
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ),
            ),

            // Botones de velocidad (1x, 2x, 3x) - debajo del texto en marquesina
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSpeedButton(1),
                    const SizedBox(width: 8),
                    _buildSpeedButton(2),
                    const SizedBox(width: 8),
                    _buildSpeedButton(3),
                  ],
                ),
              ),
            ),

            // Instrucciones
            Positioned(
              bottom: 10,
              left: 10,
              child: Text(
                'Desliza ↑↓ para cambiar tamaño',
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ),

            // Botón cerrar
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                onPressed: () {
                  _controller.stop();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
