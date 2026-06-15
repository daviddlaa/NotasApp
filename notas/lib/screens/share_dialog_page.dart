import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/note.dart';
import '../services/storage_service.dart';

class ShareDialogPage extends StatefulWidget {
  final String sharedText;

  const ShareDialogPage({super.key, required this.sharedText});

  @override
  State<ShareDialogPage> createState() => _ShareDialogPageState();
}

class _ShareDialogPageState extends State<ShareDialogPage> {
  List<Note> _recentNotes = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadRecentNotes();
  }

  Future<void> _loadRecentNotes() async {
    final notes = await StorageService.getNotes();
    setState(() {
      _recentNotes = notes.take(3).toList();
      _isLoading = false;
    });
  }

  // Función para limpiar comillas del texto
  String _cleanText(String text) {
    var cleaned = text;
    // Eliminar comillas al inicio y final si existen
    if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }
    if (cleaned.startsWith("'") && cleaned.endsWith("'")) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }
    // Eliminar espacios extra al inicio y final
    cleaned = cleaned.trim();
    return cleaned;
  }

  Future<void> _saveAsNewNote() async {
    setState(() => _isSaving = true);

    final nextNum = await StorageService.getNextNoteNumber();
    final title = 'NOTA${nextNum.toString().padLeft(3, '0')}';
    final now = DateTime.now().toIso8601String();
    final cleanedText = _cleanText(widget.sharedText);

    final note = Note(title: title, content: cleanedText, createdAt: now);

    await StorageService.addNote(note);

    if (mounted) {
      Navigator.pop(context, true);
      SystemNavigator.pop();
    }
  }

  Future<void> _appendToNote(Note note) async {
    setState(() => _isSaving = true);

    final now = DateTime.now().toIso8601String();
    final cleanedNewText = _cleanText(widget.sharedText);
    final updatedNote = Note(
      id: note.id,
      title: note.title,
      content: '${note.content}\n$cleanedNewText',
      createdAt: note.createdAt,
      updatedAt: now,
    );

    await StorageService.updateNote(updatedNote);

    if (mounted) {
      Navigator.pop(context, true);
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardar en...'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vista previa:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 100),
                      child: SingleChildScrollView(
                        child: Text(
                          _cleanText(widget.sharedText),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveAsNewNote,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(CupertinoIcons.doc_text),
                label: Text(_isSaving ? 'Guardando...' : 'Nueva nota'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'O agregar a existente',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_recentNotes.isEmpty)
              Center(
                child: Text(
                  'No hay notas guardadas',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              )
            else
              ...List.generate(_recentNotes.length, (index) {
                final note = _recentNotes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      note.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      note.content.length > 50
                          ? '${note.content.substring(0, 50)}...'
                          : note.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(CupertinoIcons.plus_circle),
                    onTap: _isSaving ? null : () => _appendToNote(note),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
