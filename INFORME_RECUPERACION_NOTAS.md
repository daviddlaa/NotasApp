# INFORME TÉCNICO: Error al Recuperar Notas al Iniciar Sesión con Otra Cuenta

## Resumen del Problema

Al iniciar sesión con una cuenta diferente, **las notas de Firebase NO se descargan automáticamente**. El sistema solo intenta subir notas pendientes, pero nunca recupera las notas de la nueva cuenta desde la nube.

---

## Arquitectura Actual (Análisis Completo)

### Flujo al iniciar sesión: Login → HomePage

```
LoginPage (_navigateToHome)
    │
    └─→ HomePage(user: FirebaseUser)
             │
             ├─ initState()
             │    └─ _syncPendingNotes()  ← SOLO sincroniza SUBIR notas pendientes
             │
             └─ _initializeScroll()
                  └─ StorageService.getNotes()  ← SOLO lee SQLite local
```

---

## Análisis del Código (PROBLEMAS IDENTIFICADOS)

### PROBLEMA #1: LoginPage - No hay sincronización al iniciar sesión

**Archivo**: `notas/lib/screens/login_page.dart` (líneas 88-95)

```dart
void _navigateToHome() {
  final user = AuthService.currentUser;
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => HomePage(user: user),  // ← Solo pasa el usuario, SIN llamar syncFromCloud()
    ),
  );
}
```

**PROBLEMA**: Al navegar a HomePage, NO se llama `syncFromCloud()` para descargar las notas de Firebase.

---

### PROBLEMA #2: HomePage - Solo sincroniza notas pendientes

**Archivo**: `notas/lib/screens/home_page.dart` (líneas 95-108)

```dart
Future<void> _syncPendingNotes() async {
  try {
    // Intenta sincronizar notas pendientes (SUBIR a Firebase)
    await StorageService.syncPendingNotes();
    // Recarga notas después de sincronizar
    final notes = await StorageService.getNotes();
    // ...
  }
}
```

**PROBLEMA**: Esta función solo **SUBE** notas pendientes a Firebase, pero **NUNCA BAJA** las notas de Firebase.

El método correcto sería `StorageService.syncFromCloud()` que está definido en `storage_service.dart` pero NO SE USA al iniciar sesión.

---

### PROBLEMA #3: StorageService.getNotes() - Solo lee SQLite local

**Archivo**: `notas/lib/services/storage_service.dart` (líneas 18-26)

```dart
static Future<List<Note>> getNotes() async {
  final user = currentUser;
  if (user == null) {
    return await _dbHelper.getNotes();
  }
  // Filtrar por usuario
  return await _dbHelper.getNotesByUser(user.uid);  // ← Solo consulta SQLite local
}
```

**PROBLEMA**: Al iniciar con nueva cuenta, solo busca en SQLite local (que puede tener notas de la cuenta anterior o estar vacío).

---

## Cómo DEBERÍA Funcionar

### Flujo Correcto:

```
LoginPage (_navigateToHome)
    │
    └─→ HomePage(user: nuevaCuenta)
             │
             ├─ initState()
             │    ├─ syncPendingNotes()      ← Subir notas pendientes (si hay)
             │    └─ syncFromCloud()          ← DESCARGAR notas de Firebase (FALTA)
             │
             └─ _initializeScroll()
                  └─ StorageService.getNotes()  ← Leer SQLite con notas correctas
```

### Código Faltante en HomePage:

```dart
// Esto debería llamarse en initState() pero no existe
Future<void> _syncFromCloud() async {
  try {
    // 1. Limpiar notas locales del usuario (por seguridad)
    // 2. Descargar notas de Firebase
    await StorageService.syncFromCloud();
  } catch (e) {
    print('Error descargando notas: $e');
  }
}
```

---

## Causa Raíz

**No hay implementación de descarga de notas desde Firebase al iniciar sesión con una cuenta nueva o diferente.**

La función `StorageService.syncFromCloud()` existe y está correctamente implementada, pero:

1. **NO se llama** cuando se inicia sesión
2. **NO se llama** en el `initState()` de HomePage
3. Solo se llama `syncPendingNotes()` que es lo opuesto (subir, no bajar)

---

## Solución Recomendada

En `home_page.dart`, agregar en `_HomePageState`:

1. Llamar a `StorageService.syncFromCloud()` en `initState()` después de `_syncPendingNotes()`

2. O mejor: hacer la limpieza de notas locales ANTES de descargar:

```dart
Future<void> _syncFromCloud() async {
  final user = currentUser;
  if (user == null) return;

  try {
    // 1. Limpiar notas locales del usuario ANTERIOR
    await DatabaseHelper.instance.clearUserNotes(user.uid);
    
    // 2. Descargar notas de Firebase
    await StorageService.syncFromCloud();
    
    // 3. Recargar notas
    final notes = await StorageService.getNotes();
    setState(() {
      _notes = notes;
    });
  } catch (e) {
    print('Error en syncFromCloud: $e');
  }
}
```

3. Modificar el `initState()` para llamar este método:

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initializeScroll();
    _handleSharedText();
    _syncPendingNotes();
    _syncFromCloud();  // ← AGREGAR ESTA LÍNEA
  });
}
```

---

## Resumen

| Aspecto | Estado Actual | Estado Esperado |
|--------|---------------|-----------------|
| Descargar notas de Firebase al login | ❌ NO IMPLEMENTADO | ✅ Debe descargarse |
| Subir notas pendientes | ✅ Implementado | ✅ Mantener |
| Función syncFromCloud() existe | ✅ Sí | ✅ Ya existe |
| Se usa en login | ❌ NO | ❌ NO |

---

**CONCLUSIÓN**: El problema es que falta llamar `syncFromCloud()` al iniciar sesión. La función ya existe pero simplemente no se invoca cuando el usuario hace login.
