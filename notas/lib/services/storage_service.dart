import '../database/database_helper.dart';
import '../models/note.dart';

class StorageService {
  static final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  static Future<List<Note>> getNotes() async {
    return await _dbHelper.getNotes();
  }

  static Future<int> addNote(Note note) async {
    return await _dbHelper.insert(note);
  }

  static Future<int> updateNote(Note note) async {
    return await _dbHelper.update(note);
  }

  static Future<int> deleteNote(int id) async {
    return await _dbHelper.delete(id);
  }

  /// Search notes by title or content
  static Future<List<Note>> searchNotes(String query) async {
    return await _dbHelper.searchNotes(query);
  }

  /// Get the next available note number for generating default titles like NOTA001, NOTA002, etc.
  static Future<int> getNextNoteNumber() async {
    final notes = await _dbHelper.getNotes();
    int maxNumber = 0;

    for (final note in notes) {
      // Look for titles that match the pattern NOTA001, NOTA002, etc.
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
}
