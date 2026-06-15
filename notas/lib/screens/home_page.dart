import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/note.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'note_editor_page.dart';
import 'note_reader_page.dart';
import 'share_dialog_page.dart';

class HomePage extends StatefulWidget {
  final int currentColorIndex;
  final Function(int) onColorChanged;
  final String? sharedText;
  final VoidCallback? onSharedTextHandled;

  const HomePage({
    super.key,
    required this.currentColorIndex,
    required this.onColorChanged,
    this.sharedText,
    this.onSharedTextHandled,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  double _scrollPosition = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScroll();
      _handleSharedText();
    });
  }

  Future<void> _handleSharedText() async {
    if (widget.sharedText != null && widget.sharedText!.isNotEmpty) {
      // Abrir dialogo de compartir con opciones
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ShareDialogPage(sharedText: widget.sharedText!),
        ),
      );
      // Si se guardó correctamente, actualizar notas
      if (result == true) {
        final notes = await StorageService.getNotes();
        setState(() {
          _notes = notes;
          if (_searchQuery.isNotEmpty) {
            _filteredNotes = notes
                .where(
                  (note) =>
                      note.title.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      note.content.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ),
                )
                .toList();
          }
        });
        // Mostrar mensaje de éxito
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Guardado exitosamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
      // Notificar que se manejó el texto compartido
      widget.onSharedTextHandled?.call();
    }
  }

  Future<void> _initializeScroll() async {
    final notes = await StorageService.getNotes();
    setState(() {
      _notes = notes;
      _isLoading = false;
    });
    _scrollController.addListener(_saveScrollPosition);
    _restoreScrollPosition();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_saveScrollPosition);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _saveScrollPosition() {
    if (_scrollController.hasClients) {
      _scrollPosition = _scrollController.offset;
    }
  }

  void _restoreScrollPosition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _scrollPosition > 0) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final targetPosition = _scrollPosition.clamp(0.0, maxScroll);
        _scrollController.jumpTo(targetPosition);
      }
    });
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _searchQuery = query;
    });

    if (query.isEmpty) {
      setState(() {
        _filteredNotes = [];
      });
      return;
    }

    final results = await StorageService.searchNotes(query);
    setState(() {
      _filteredNotes = results;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _filteredNotes = [];
    });
  }

  Future<void> _deleteNote(Note note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Apunte'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar este apunte?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && note.id != null) {
      await StorageService.deleteNote(note.id!);
      final notes = await StorageService.getNotes();
      setState(() {
        _notes = notes;
        if (_searchQuery.isNotEmpty) {
          _filteredNotes = notes
              .where(
                (note) =>
                    note.title.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    note.content.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();
        }
      });
    }
  }

  Future<void> _navigateToNote(Note note) async {
    _saveScrollPosition();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteReaderPage(note: note)),
    );
    final notes = await StorageService.getNotes();
    setState(() {
      _notes = notes;
      if (_searchQuery.isNotEmpty) {
        _filteredNotes = notes
            .where(
              (note) =>
                  note.title.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  note.content.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ),
            )
            .toList();
      }
    });
    _restoreScrollPosition();
  }

  void _showConfigSelector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, animation, secondaryAnimation) {
        return Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            builder: (context, value, child) =>
                Transform.scale(scale: value, child: child),
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxHeight: 500),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Color Section
                    Text(
                      'Color',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: List.generate(
                        AppTheme.themeColors.length,
                        (index) => TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 200 + (index * 50)),
                          curve: Curves.easeOut,
                          builder: (context, value, child) =>
                              Transform.scale(scale: value, child: child),
                          child: GestureDetector(
                            onTap: () {
                              widget.onColorChanged(index);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.themeColors[index].color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: widget.currentColorIndex == index
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.themeColors[index].color
                                        .withValues(alpha: 0.4),
                                    blurRadius:
                                        widget.currentColorIndex == index
                                        ? 10
                                        : 4,
                                    spreadRadius:
                                        widget.currentColorIndex == index
                                        ? 2
                                        : 0,
                                  ),
                                ],
                              ),
                              child: widget.currentColorIndex == index
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 20,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        AppTheme.themeColors[widget.currentColorIndex].name,
                        key: ValueKey('color-${widget.currentColorIndex}'),
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSearching = _searchQuery.isNotEmpty;
    final displayNotes = isSearching ? _filteredNotes : _notes;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis Apuntes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.gear),
            onPressed: () => _showConfigSelector(context),
            tooltip: 'Configuración',
          ),
        ],
      ),
      body: Column(
        children: [
          // Floating Search Bar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _performSearch,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Buscar notas...',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                prefixIcon: Icon(
                  CupertinoIcons.search,
                  color: Colors.grey.shade500,
                ),
                suffixIcon: isSearching
                    ? IconButton(
                        icon: Icon(
                          CupertinoIcons.xmark,
                          color: Colors.grey.shade500,
                          size: 20,
                        ),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayNotes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSearching
                              ? CupertinoIcons.search
                              : CupertinoIcons.doc_text,
                          size: 80,
                          color: colorScheme.primary.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isSearching
                              ? 'No se encontraron resultados'
                              : 'No hay apuntes',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (!isSearching) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Toca el botón + para crear uno',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      final notes = await StorageService.getNotes();
                      setState(() {
                        _notes = notes;
                        if (isSearching) {
                          _filteredNotes = notes
                              .where(
                                (note) =>
                                    note.title.toLowerCase().contains(
                                      _searchQuery.toLowerCase(),
                                    ) ||
                                    note.content.toLowerCase().contains(
                                      _searchQuery.toLowerCase(),
                                    ),
                              )
                              .toList();
                        }
                      });
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: displayNotes.length,
                      itemBuilder: (context, index) {
                        final note = displayNotes[index];
                        final contentLines = note.content.split('\n').length;
                        final showFull = contentLines <= 2;

                        return Dismissible(
                          key: Key('note_${note.id ?? index}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade400,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              CupertinoIcons.trash,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (_) => _deleteNote(note),
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _navigateToNote(note),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Borde izquierdo de color
                                    Container(
                                      width: 4,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: colorScheme
                                                      .primaryContainer,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  note.title,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: colorScheme
                                                        .onPrimaryContainer,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            note.content,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade700,
                                              height: 1.4,
                                            ),
                                            maxLines: showFull ? null : 2,
                                            overflow: showFull
                                                ? TextOverflow.visible
                                                : TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Icon(
                                                CupertinoIcons.clock,
                                                size: 14,
                                                color: Colors.grey.shade500,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatDate(note.createdAt),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NoteEditorPage()),
          );
          final notes = await StorageService.getNotes();
          setState(() {
            _notes = notes;
            if (_searchQuery.isNotEmpty) {
              _filteredNotes = notes
                  .where(
                    (note) =>
                        note.title.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ||
                        note.content.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ),
                  )
                  .toList();
            }
          });
        },
        child: const Icon(CupertinoIcons.plus),
      ),
    );
  }
}
