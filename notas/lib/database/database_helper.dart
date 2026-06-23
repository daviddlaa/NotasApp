import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/note.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  DatabaseHelper._init();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDB();

    return _database!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'notes.db');

    return await openDatabase(
      path,
      version: 3, // Version incrementada para is_pinned
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT,
            user_id TEXT,
            firestore_id TEXT,
            sync_status TEXT DEFAULT 'pending',
            is_pinned INTEGER DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Agregar nuevas columnas si es upgrade desde version 1
          await db.execute('ALTER TABLE notes ADD COLUMN user_id TEXT');
          await db.execute('ALTER TABLE notes ADD COLUMN firestore_id TEXT');
          await db.execute(
            "ALTER TABLE notes ADD COLUMN sync_status TEXT DEFAULT 'pending'",
          );
        }
        if (oldVersion < 3) {
          // Agregar columna is_pinned si es upgrade desde version 2
          await db.execute(
            'ALTER TABLE notes ADD COLUMN is_pinned INTEGER DEFAULT 0',
          );
        }
      },
    );
  }

  Future<int> insert(Note note) async {
    final db = await database;

    return db.insert('notes', note.toMap());
  }

  Future<List<Note>> getNotes() async {
    final db = await database;

    final result = await db.query('notes', orderBy: 'id DESC');

    return result.map((e) => Note.fromMap(e)).toList();
  }

  // Obtener notas de un usuario específico
  Future<List<Note>> getNotesByUser(String userId) async {
    final db = await database;

    final result = await db.query(
      'notes',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );

    return result.map((e) => Note.fromMap(e)).toList();
  }

  Future<int> update(Note note) async {
    final db = await database;

    return db.update(
      'notes',
      note.toMap(),
      where: 'id=?',
      whereArgs: [note.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await database;

    return db.delete('notes', where: 'id=?', whereArgs: [id]);
  }

  Future<List<Note>> searchNotes(String query) async {
    final db = await database;

    final result = await db.query(
      'notes',
      where: 'title LIKE ? OR content LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'id DESC',
    );

    return result.map((e) => Note.fromMap(e)).toList();
  }

  // Obtener notas pendientes de sincronizar
  Future<List<Note>> getPendingNotes() async {
    final db = await database;

    final result = await db.query(
      'notes',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
    );

    return result.map((e) => Note.fromMap(e)).toList();
  }

  // Actualizar estado de sincronización
  Future<int> updateSyncStatus(
    int id,
    String status, {
    String? firestoreId,
  }) async {
    final db = await database;

    if (firestoreId != null) {
      return db.update(
        'notes',
        {'sync_status': status, 'firestore_id': firestoreId},
        where: 'id=?',
        whereArgs: [id],
      );
    }

    return db.update(
      'notes',
      {'sync_status': status},
      where: 'id=?',
      whereArgs: [id],
    );
  }

  // Limpiar notas de un usuario (para sincronización)
  Future<int> clearUserNotes(String userId) async {
    final db = await database;

    return db.delete('notes', where: 'user_id = ?', whereArgs: [userId]);
  }

  // Actualizar nota con firestoreId
  Future<int> updateFirestoreId(int id, String firestoreId) async {
    final db = await database;

    return db.update(
      'notes',
      {'firestore_id': firestoreId, 'sync_status': 'synced'},
      where: 'id=?',
      whereArgs: [id],
    );
  }

  // Obtener notas ancladas (favoritos)
  Future<List<Note>> getPinnedNotes() async {
    final db = await database;

    final result = await db.query(
      'notes',
      where: 'is_pinned = ?',
      whereArgs: [1],
      orderBy: 'id DESC',
    );

    return result.map((e) => Note.fromMap(e)).toList();
  }

  // Actualizar estado de anclaje (toggle pin)
  Future<int> togglePinned(int id, bool isPinned) async {
    final db = await database;

    return db.update(
      'notes',
      {'is_pinned': isPinned ? 1 : 0},
      where: 'id=?',
      whereArgs: [id],
    );
  }
}
