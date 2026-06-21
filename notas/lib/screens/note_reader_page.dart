import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../models/note.dart';
import '../services/storage_service.dart';
import 'note_editor_page.dart';

class NoteReaderPage extends StatefulWidget {
  final Note note;

  const NoteReaderPage({super.key, required this.note});

  @override
  State<NoteReaderPage> createState() => _NoteReaderPageState();
}

class _NoteReaderPageState extends State<NoteReaderPage> {
  late Note _note;
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;
  double _fontSize = 20.0;

  static const List<double> fontSizes = <double>[
    18.0,
    22.0,
    26.0,
  ]; // Pequeno, Normal, Grande
  int _currentFontIndex = 1; // Empieza en Normal

  @override
  void initState() {
    super.initState();
    _note = widget.note;
    _fontSize = _calculateInitialFontSize(_note.content);
  }

  double _calculateInitialFontSize(String content) {
    final length = content.length;
    if (length < 200) return 26.0;
    if (length < 500) return 22.0;
    if (length < 1000) return 18.0;
    return 14.0;
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

  Future<void> _shareAsImage() async {
    setState(() => _isSharing = true);

    try {
      final Uint8List? imageBytes = await _screenshotController.capture(
        pixelRatio: 3.0,
        delay: const Duration(milliseconds: 100),
      );

      if (imageBytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al crear imagen')),
          );
        }
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/nota_${_note.title}.png');
      await file.writeAsBytes(imageBytes);

      await Share.shareXFiles([XFile(file.path)], text: _note.title);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  void copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Texto copiado al portapapeles')),
    );
  }

  Future<void> _deleteNote() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Apunte'),
        content: const Text(' Seguro que quieres eliminar este apunte?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && _note.id != null) {
      await StorageService.deleteNote(_note.id!);
      if (mounted) {
        // Volver a HomePage directamente
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    }
  }

  // Ciclo: toca para cambiar tamano
  void _cycleFontSize() {
    setState(() {
      _currentFontIndex = (_currentFontIndex + 1) % fontSizes.length;
      _fontSize = fontSizes[_currentFontIndex];
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // Ir a HomePage cuando se presiona back
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_note.title),
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(CupertinoIcons.trash),
              onPressed: _deleteNote,
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.textformat_size),
              onPressed: _cycleFontSize,
              tooltip: 'Cambiar tamaño de letra',
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Screenshot(
                  controller: _screenshotController,
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _note.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Creado: ${_formatDate(_note.createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),
                        SelectableText(
                          _note.content,
                          style: TextStyle(
                            fontSize: _fontSize,
                            height: 1.8,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
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
                        onPressed: () => copyText(_note.content),
                        icon: const Icon(CupertinoIcons.doc_on_doc),
                        label: const Text('Copiar'),
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
                        onPressed: _isSharing ? null : _shareAsImage,
                        icon: _isSharing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(CupertinoIcons.share),
                        label: Text(_isSharing ? 'Enviando...' : 'Compartir'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push<Note>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NoteEditorPage(note: _note),
                            ),
                          );
                          if (result != null) {
                            setState(() => _note = result);
                          }
                        },
                        icon: const Icon(CupertinoIcons.pencil),
                        label: const Text('Editar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
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
      ),
    );
  }
}
