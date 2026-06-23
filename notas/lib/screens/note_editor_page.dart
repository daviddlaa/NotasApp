// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/note.dart';
import '../services/storage_service.dart';
import 'note_reader_page.dart';

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
  String? _createdAt;
  String? _updatedAt;

  bool get isEditing => widget.note != null && widget.note!.id != null;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  Future<void> _initControllers() async {
    if (widget.note != null) {
      titleController.text = widget.note!.title;
      contentController.text = widget.note!.content;
      _createdAt = widget.note!.createdAt;
      _updatedAt = widget.note!.updatedAt;
    } else if (widget.initialContent != null &&
        widget.initialContent!.isNotEmpty) {
      contentController.text = widget.initialContent!;
      final nextNum = await StorageService.getNextNoteNumber();
      titleController.text = 'NOTA${nextNum.toString().padLeft(3, '0')}';
      _createdAt = DateTime.now().toIso8601String();
    } else {
      final nextNum = await StorageService.getNextNoteNumber();
      titleController.text = 'NOTA${nextNum.toString().padLeft(3, '0')}';
      _createdAt = DateTime.now().toIso8601String();
    }
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateStr;
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
      // Usar copyWith para preservar userId, firestoreId y syncStatus
      savedNote = widget.note!.copyWith(
        title: title.isEmpty ? widget.note!.title : title,
        content: content,
        updatedAt: now,
      );
      await StorageService.updateNote(savedNote);
    } else {
      final newNote = Note(
        title: title.isEmpty ? 'SIN TÍTULO' : title,
        content: content,
        createdAt: now,
      );
      savedNote = await StorageService.addNote(newNote);
    }

    if (mounted) {
      if (isEditing) {
        // Editando existente: volver al visor con cambios
        Navigator.pop(context, savedNote);
      } else {
        // Nueva nota: ir al visor de la nota
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => NoteReaderPage(note: savedNote)),
        );
      }
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

      // Actualizar UI para activar botón Deshacer
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _undoPaste() {
    if (_history.isNotEmpty) {
      contentController.text = _history.removeLast();
      setState(() {});
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 20,
                      color: Colors.black.withValues(alpha: 0.08),
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título editable en formato de badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: titleController,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Título del apunte',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Fechas
                    if (_createdAt != null) ...[
                      Text(
                        'Creado: ${_formatDate(_createdAt!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      if (_updatedAt != null && _updatedAt!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Modificado: ${_formatDate(_updatedAt!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    // Contenido editable
                    TextField(
                      controller: contentController,
                      maxLines: null,
                      style: TextStyle(
                        fontSize: 20,
                        height: 1.8,
                        color: Colors.black87,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Escribe tu apunte aquí...',
                        border: InputBorder.none,
                        fillColor: Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Barra inferior con acciones
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  blurRadius: 10,
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _pasteFromClipboard();
                      },
                      icon: const Icon(CupertinoIcons.doc_on_clipboard),
                      label: const Text('Pegar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.secondaryContainer,
                        foregroundColor: colorScheme.onSecondaryContainer,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _history.isEmpty ? null : _undoPaste,
                      icon: const Icon(CupertinoIcons.arrow_uturn_left),
                      label: const Text('Deshacer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade100,
                        foregroundColor: Colors.orange.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : saveNote,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _isSaving
                                  ? CupertinoIcons.floppy_disk
                                  : CupertinoIcons.checkmark_circle,
                            ),
                      label: Text(
                        _isSaving
                            ? 'Guardando...'
                            : 'Guardar', // Guardado instantáneo ahora
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSaving
                            ? colorScheme.primary
                            : Colors.green.shade600,
                        foregroundColor: _isSaving
                            ? colorScheme.onPrimary
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
