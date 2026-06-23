import 'package:firebase_auth/firebase_auth.dart';

import '../database/database_helper.dart';
import '../models/note.dart';
import 'firestore_service.dart';

class StorageService {
  static final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Obtener usuario actual
  static User? get currentUser => FirebaseAuth.instance.currentUser;

  // ========== OPERACIONES LOCALES (SQLite) ==========

  // Obtener notas locales del usuario actual
  static Future<List<Note>> getNotes() async {
    final user = currentUser;
    if (user == null) {
      // Si no hay usuario, obtener todas (para backward compatibility)
      return await _dbHelper.getNotes();
    }
    // Filtrar por usuario
    return await _dbHelper.getNotesByUser(user.uid);
  }

  // Agregar nota (guarda en SQLite Y Firebase) - devuelve la nota completa
  static Future<Note> addNote(Note note) async {
    final user = currentUser;

    // 1. Guardar en SQLite primero (siempre disponible) - INSTANTÁNEO
    final noteWithUser = note.copyWith(
      userId: user?.uid,
      syncStatus: 'pending',
    );
    final localId = await _dbHelper.insert(noteWithUser);

    // Crear nota con ID
    final noteWithId = noteWithUser.copyWith(id: localId);
    Note finalNote = noteWithId;

    // 2. Sincronizar con Firebase EN BACKGROUND (sin await)
    // Esto permite que la UI no se bloquee
    if (user != null) {
      _syncNoteToCloudBackground(noteWithId);
    }

    return finalNote;
  }

  // Sincronizar nota a Firebase en background (sin esperar)
  static Future<void> _syncNoteToCloudBackground(Note note) async {
    try {
      final firestoreId = await FirestoreService.uploadToCloud(note);

      if (firestoreId != null && note.id != null) {
        // Actualizar con el ID de Firebase y marcar como synced
        await _dbHelper.updateFirestoreId(note.id!, firestoreId);
      }
    } catch (e) {
      // Silencioso - la nota queda como pending y se sincroniza después
      print('Sync en background pendiente: $e');
    }
  }

  // Actualizar nota
  static Future<int> updateNote(Note note) async {
    final user = currentUser;
    final noteWithUser = note.copyWith(
      userId: user?.uid,
      syncStatus: 'pending',
    );

    // 1. Actualizar en SQLite
    final result = await _dbHelper.update(noteWithUser);

    // 2. Sincronizar con Firebase EN BACKGROUND (sin await)
    if (user != null && note.firestoreId != null) {
      _updateNoteToCloudBackground(noteWithUser);
    }

    return result;
  }

  // Actualizar nota en background (sin esperar)
  static Future<void> _updateNoteToCloudBackground(Note note) async {
    try {
      final success = await FirestoreService.updateNote(note);
      if (success) {
        // Marcar como synced si Firebase funcionó
        await _dbHelper.updateFirestoreId(note.id!, note.firestoreId!);
      }
    } catch (e) {
      // Silencioso - la nota queda como pending
      print('Update en background pendiente: $e');
    }
  }

  // Eliminar nota
  static Future<int> deleteNote(int id) async {
    final user = currentUser;

    // Obtener nota para ver si tiene firestoreId
    final notes = await _dbHelper.getNotes();
    final note = notes.firstWhere(
      (n) => n.id == id,
      orElse: () => Note(title: '', content: '', createdAt: ''),
    );

    // 1. Eliminar de SQLite
    final result = await _dbHelper.delete(id);

    // 2. Eliminar de Firebase si existe
    if (user != null && note.firestoreId != null) {
      FirestoreService.deleteNote(note.firestoreId!);
    }

    return result;
  }

  // Buscar notas
  static Future<List<Note>> searchNotes(String query) async {
    final user = currentUser;
    if (user == null) {
      return await _dbHelper.searchNotes(query);
    }

    // Buscar solo en notas del usuario
    final allNotes = await _dbHelper.getNotesByUser(user.uid);
    final lowerQuery = query.toLowerCase();

    return allNotes
        .where(
          (note) =>
              note.title.toLowerCase().contains(lowerQuery) ||
              note.content.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }

  // ========== SINCRONIZACIÓN ==========

  // Sincronizar desde Firebase (para teléfono nuevo o login)
  static Future<void> syncFromCloud() async {
    final user = currentUser;
    if (user == null) return;

    try {
      // 1. Obtener notas de Firebase
      final cloudNotes = await FirestoreService.syncFromCloud();

      // 2. Limpiar notas locales del usuario
      await _dbHelper.clearUserNotes(user.uid);

      // 3. Guardar notas de Firebase en SQLite
      for (final note in cloudNotes) {
        final localNote = note.copyWith(
          id: null, // Auto-increment
          syncStatus: 'synced',
        );
        await _dbHelper.insert(localNote);
      }

      print('Sincronización completada: ${cloudNotes.length} notas');
    } catch (e) {
      print('Error en syncFromCloud: $e');
    }
  }

  // Subir notas pendientes a Firebase
  static Future<void> syncPendingNotes() async {
    final user = currentUser;
    if (user == null) return;

    try {
      final pendingNotes = await _dbHelper.getPendingNotes();

      for (final note in pendingNotes) {
        await _syncNoteToCloud(note);
      }
    } catch (e) {
      print('Error en syncPendingNotes: $e');
    }
  }

  // Sincronizar nota individual a Firebase
  static Future<void> _syncNoteToCloud(Note note) async {
    try {
      final firestoreId = await FirestoreService.uploadToCloud(note);

      if (firestoreId != null && note.id != null) {
        // Actualizar con el ID de Firebase
        await _dbHelper.updateFirestoreId(note.id!, firestoreId);
      }
    } catch (e) {
      print('Error sincronizando nota: $e');
    }
  }

  // ========== UTILIDADES ==========

  // Obtener siguiente número de nota
  static Future<int> getNextNoteNumber() async {
    final notes = await getNotes();
    int maxNumber = 0;

    for (final note in notes) {
      if (note.title.startsWith('NOTA') && note.title.length >= 7) {
        final suffix = note.title.substring(4);
        final number = int.tryParse(suffix);
        if (number != null && number > maxNumber) {
          maxNumber = number;
        }
      }
    }

    return maxNumber + 1;
  }

  // Forzar sincronización completa
  static Future<void> forceFullSync() async {
    final user = currentUser;
    if (user == null) return;

    // 1. Subir todas las pendientes
    await syncPendingNotes();

    // 2. Descargar todas del cloud
    await syncFromCloud();
  }

  // ========== NOTAS ANCLADAS (FAVORITOS) ==========

  // Obtener notas ancladas del usuario actual
  static Future<List<Note>> getPinnedNotes() async {
    final user = currentUser;
    if (user == null) {
      return await _dbHelper.getPinnedNotes();
    }
    // Filtrar notas ancladas por usuario
    final allNotes = await _dbHelper.getNotesByUser(user.uid);
    return allNotes.where((note) => note.isPinned).toList();
  }

  // Alternar estado de anclaje (anclar/desanclar)
  static Future<void> togglePinned(Note note) async {
    if (note.id == null) return;

    final newPinnedState = !note.isPinned;

    // 1. Actualizar en SQLite
    await _dbHelper.togglePinned(note.id!, newPinnedState);

    // 2. Sincronizar cambio con Firebase
    final updatedNote = note.copyWith(
      isPinned: newPinnedState,
      syncStatus: 'pending',
      updatedAt: DateTime.now().toIso8601String(),
    );

    if (currentUser != null && note.firestoreId != null) {
      _updateNoteToCloudBackground(updatedNote);
    }
  }
}
