import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/note.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _notesCollection = _firestore.collection(
    'notes',
  );

  // Obtener usuario actual
  static User? get currentUser => FirebaseAuth.instance.currentUser;

  // Obtener notes Collection filtradas por usuario
  static Query _getUserNotesQuery() {
    final user = currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }
    return _notesCollection.where('userId', isEqualTo: user.uid);
  }

  // Obtener todas las notas del usuario actual desde Firebase
  static Future<List<Note>> getNotes() async {
    try {
      final query = _getUserNotesQuery();
      // Nota: No ordenamos por múltiples campos para evitar error de índice
      // Ordenaremos en el cliente después
      final snapshot = await query.get();

      final notes = snapshot.docs.map((doc) {
        return Note.fromFirestoreMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();

      // Ordenar por createdAt descendente en el cliente
      notes.sort((a, b) {
        final dateA = DateTime.tryParse(a.createdAt) ?? DateTime(1970);
        final dateB = DateTime.tryParse(b.createdAt) ?? DateTime(1970);
        return dateB.compareTo(dateA);
      });

      return notes;
    } catch (e) {
      print('Error en getNotes de Firestore: $e');
      return [];
    }
  }

  // Guardar una nueva nota en Firebase
  static Future<String?> addNote(Note note) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final noteWithUser = note.copyWith(
        userId: user.uid,
        syncStatus: 'synced',
      );

      final docRef = await _notesCollection.add(noteWithUser.toFirestoreMap());
      return docRef.id;
    } catch (e) {
      print('Error en addNote de Firestore: $e');
      return null;
    }
  }

  // Actualizar una nota en Firebase
  static Future<bool> updateNote(Note note) async {
    try {
      if (note.firestoreId == null) {
        print('Nota sin firestoreId, no se puede actualizar en Firestore');
        return false;
      }

      final user = currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final docRef = _notesCollection.doc(note.firestoreId);
      await docRef.update({
        'title': note.title,
        'content': note.content,
        'updatedAt': DateTime.now().toIso8601String(),
        'userId': user.uid, // Incluir userId para verificación de seguridad
      });
      return true;
    } catch (e) {
      print('Error en updateNote de Firestore: $e');
      return false;
    }
  }

  // Eliminar una nota de Firebase
  static Future<bool> deleteNote(String firestoreId) async {
    try {
      final docRef = _notesCollection.doc(firestoreId);
      await docRef.delete();
      return true;
    } catch (e) {
      print('Error en deleteNote de Firestore: $e');
      return false;
    }
  }

  // Buscar notas por título o contenido
  static Future<List<Note>> searchNotes(String query) async {
    try {
      final user = currentUser;
      if (user == null) {
        return [];
      }

      // Firestore no tiene LIKE, filtramos client-side
      final allNotes = await getNotes();
      final lowerQuery = query.toLowerCase();

      return allNotes
          .where(
            (note) =>
                note.title.toLowerCase().contains(lowerQuery) ||
                note.content.toLowerCase().contains(lowerQuery),
          )
          .toList();
    } catch (e) {
      print('Error en searchNotes de Firestore: $e');
      return [];
    }
  }

  // Sincronizar notas locales con Firebase (traer todas las del cloud)
  static Future<List<Note>> syncFromCloud() async {
    try {
      return await getNotes();
    } catch (e) {
      print('Error en syncFromCloud: $e');
      return [];
    }
  }

  // Subir nota local a Firebase
  static Future<String?> uploadToCloud(Note note) async {
    try {
      if (note.firestoreId != null) {
        // Ya existe en Firebase, actualizar
        await updateNote(note);
        return note.firestoreId;
      } else {
        // Nueva nota, crear
        return await addNote(note);
      }
    } catch (e) {
      print('Error en uploadToCloud: $e');
      return null;
    }
  }
}
