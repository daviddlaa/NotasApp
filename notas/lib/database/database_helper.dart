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
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT
          )
        ''');
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
}
