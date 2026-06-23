# TODO - Nota Player Letra Grande

## Plan de cambios para note_player_page.dart

### Estado Actual
- Tamaño inicial: 40 (pequeño)
- El usuario tiene que agrandar manualmente cada vez

### Cambio requerido
- El Note Player debe empezar con letra grande (tamaño máximo)
- Mantener el gesto de agrandar/hacer pequeño

### Pasos para implementar:
1. [X] Analizar el código actual
2. [X] CrearPlan
3. [X] Modificar _fontSize inicial para que sea _maxFontSize
4. [X] Probar que el cambio funciona

### Cambios realizados:
- Cambiado `_fontSize = 40.0` a declaración only (late double)
- En initState, agregado `_fontSize = _maxFontSize` para que siempre inicie con tamaño máximo
- El gesto vertical se mantiene: permite hacer la letra más pequeña deslizando hacia abajo
