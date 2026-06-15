// ignore_for_file: use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/note.dart';
import '../services/storage_service.dart';

class NoteEditorPage extends StatefulWidget {
  final Note? note;
  final String? initialContent;

  const NoteEditorPage({super.key, this.note, this.initialContent});

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  bool _isSaving = false;
  final List<String> _history = []; // Historial de cambios
  static const int _maxHistory = 5; // Máximo 5 cambios

  bool get isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  Future<void> _initControllers() async {
    if (widget.note != null) {
      titleController.text = widget.note!.title;
      contentController.text = widget.note!.content;
    } else if (widget.initialContent != null &&
        widget.initialContent!.isNotEmpty) {
      contentController.text = widget.initialContent!;
      final nextNum = await StorageService.getNextNoteNumber();
      titleController.text = 'NOTA${nextNum.toString().padLeft(3, '0')}';
    } else {
      final nextNum = await StorageService.getNextNoteNumber();
      titleController.text = 'NOTA${nextNum.toString().padLeft(3, '0')}';
    }
  }

  Future<void> saveNote() async {
    final title = titleController.text.trim();
    final content = contentController.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El contenido es requerido')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final now = DateTime.now().toIso8601String();
    Note savedNote;

    if (isEditing) {
      savedNote = Note(
        id: widget.note!.id,
        title: title.isEmpty ? widget.note!.title : title,
        content: content,
        createdAt: widget.note!.createdAt,
        updatedAt: now,
      );
      await StorageService.updateNote(savedNote);
    } else {
      savedNote = Note(
        title: title.isEmpty ? 'SIN TÍTULO' : title,
        content: content,
        createdAt: now,
      );
      await StorageService.addNote(savedNote);
    }

    if (mounted) {
      Navigator.pop(context, savedNote);
    }
  }

  // Agregar al historial antes de hacer cambios
  void _addToHistory() {
    _history.add(contentController.text);
    // Mantener solo los últimos 5 cambios
    while (_history.length > _maxHistory) {
      _history.removeAt(0);
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      // Guardar estado actual en historial
      _addToHistory();

      if (contentController.text.isNotEmpty) {
        contentController.text = '${contentController.text}\n${data.text}';
      } else {
        contentController.text = data.text!;
      }
    }
  }

  void _undoPaste() {
    if (_history.isNotEmpty) {
      contentController.text = _history.removeLast();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Apunte' : 'Nuevo Apunte'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: titleController,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: 'Título del apunte',
                    border: InputBorder.none,
                    fillColor: Colors.transparent,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Botones de pegar y deshacer lado a lado
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pasteFromClipboard,
                    icon: const Icon(CupertinoIcons.doc_on_clipboard, size: 24),
                    label: const Text('Pegar', style: TextStyle(fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: colorScheme.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _undoPaste,
                    icon: const Icon(CupertinoIcons.arrow_uturn_left, size: 24),
                    label: const Text(
                      'Deshacer',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: contentController,
                    expands: true,
                    maxLines: null,
                    textAlignVertical: TextAlignVertical.top,
                    style: TextStyle(fontSize: 16, height: 1.6),
                    decoration: const InputDecoration(
                      hintText: 'Escribe tu apunte aquí...',
                      border: InputBorder.none,
                      fillColor: Colors.transparent,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : saveNote,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(CupertinoIcons.floppy_disk),
                label: Text(_isSaving ? 'Guardando...' : 'Guardar Apunte'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
