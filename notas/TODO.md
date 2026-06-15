# TODO - Mejoras de Diseño Visual

## Selección del usuario:
- 1A: Cupertino Icons (estilo iOS elegante)
- 2B: Borde izquierdo de color según tema
- 3B: FAB circular clásico estilizado
- 4B: Swipe para eliminar
- 5B: AppBar sin gradiente, más limpio

---

## Estado: COMPLETADO ✓

### Cambios realizados:

## Paso 1: Iconos Cupertino
- [x] Import `package:flutter/cupertino.dart` en todos los archivos
- [x] Actualizar iconos en home_page.dart (gear, plus, clock, trash, search)
- [x] Actualizar iconos en note_editor_page.dart (doc_on_clipboard, floppy_disk)
- [x] Actualizar iconos en note_reader_page.dart (trash, textformat_size, doc_on_doc, share, pencil)

## Paso 2: Borde izquierdo de color en tarjetas
- [x] Modificar Card en home_page.dart para añadir Container con borde izquierdo de color (4px)
- [x] Usar colorScheme.primary para el borde

## Paso 3: FAB estilizado
- [x] Cambiar FloatingActionButton.extended a FloatingActionButton circular
- [x] Usar CupertinoIcons.plus

## Paso 4: Swipe actions
- [x] Agregar widget Dismissible para swipe eliminar
- [x] Animación con background de color rojo y icono de trash

## Paso 5: AppBar más limpio
- [x] Remover gradient del flexibleSpace
- [x] Usar elevation: 0
- [x] Estilo más minimal

## Archivos actualizados:
- notas/lib/screens/home_page.dart
- notas/lib/screens/note_editor_page.dart
- notas/lib/screens/note_reader_page.dart
