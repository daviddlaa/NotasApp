import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../models/note.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'login_page.dart';
import 'note_editor_page.dart';
import 'note_reader_page.dart';
import 'share_dialog_page.dart';

/// Widget separado para el selector de color con estado propio
class _ColorSelectorWidget extends StatefulWidget {
  final int initialIndex;
  final Function(int) onColorSelected;
  final ColorScheme colorScheme;

  const _ColorSelectorWidget({
    required this.initialIndex,
    required this.onColorSelected,
    required this.colorScheme,
  });

  @override
  State<_ColorSelectorWidget> createState() => _ColorSelectorWidgetState();
}

class _ColorSelectorWidgetState extends State<_ColorSelectorWidget> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    // Usar el índice inicial capturado al crear el widget
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
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
                Text(
                  'Color',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.colorScheme.primary,
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
                        onTap: () async {
                          // Actualizar el estado local
                          setState(() {
                            _selectedIndex = index;
                          });
                          // Notificar al widget padre
                          widget.onColorSelected(index);
                          // Esperar animación
                          await Future.delayed(
                            const Duration(milliseconds: 350),
                          );
                          if (mounted) Navigator.pop(context);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.themeColors[index].color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedIndex == index
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.themeColors[index].color
                                    .withValues(alpha: 0.4),
                                blurRadius: _selectedIndex == index ? 10 : 4,
                                spreadRadius: _selectedIndex == index ? 2 : 0,
                              ),
                            ],
                          ),
                          child: _selectedIndex == index
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
                    AppTheme.themeColors[_selectedIndex].name,
                    key: ValueKey('color-$_selectedIndex'),
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.colorScheme.primary,
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
  }
}

class HomePage extends StatefulWidget {
  final int currentColorIndex;
  final Function(int) onColorChanged;
  final String? sharedText;
  final VoidCallback? onSharedTextHandled;
  final User? user;

  const HomePage({
    super.key,
    required this.currentColorIndex,
    required this.onColorChanged,
    this.sharedText,
    this.onSharedTextHandled,
    this.user,
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
  bool _showPinnedOnly = false; // Filtrar solo favoritos

  // Obtener el color actual de la app
  Color get _appColor => AppTheme.themeColors[widget.currentColorIndex].color;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScroll();
      _handleSharedText();
      _syncPendingNotes(); // Sincronizar notas pendientes al abrir la app
      _syncFromCloud(); // Descargar notas de Firebase para nueva cuenta
    });
  }

  // Sincronizar notas pendientes desde Firebase
  Future<void> _syncPendingNotes() async {
    try {
      // Intentar sincronizar notas pendientes en background
      await StorageService.syncPendingNotes();
      // Recargar notas después de sincronizar
      final notes = await StorageService.getNotes();
      setState(() {
        _notes = notes;
      });
      print('Notas pendientes sincronizadas');
    } catch (e) {
      print('Error sincronizando notas: $e');
    }
  }

  // Descargar notas desde Firebase (para nueva cuenta o cuenta diferente)
  Future<void> _syncFromCloud() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Descargar notas de Firebase para el usuario actual
      await StorageService.syncFromCloud();

      // Recargar notas después de sincronizar
      final notes = await StorageService.getNotes();
      setState(() {
        _notes = notes;
        _filteredNotes = [];
      });
      print('Notas descargadas desde Firebase: ${notes.length}');
    } catch (e) {
      print('Error descargando notas desde Firebase: $e');
    }
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

  // Toggle mostrar solo favoritos
  void _togglePinnedFilter() {
    setState(() {
      _showPinnedOnly = !_showPinnedOnly;
    });
  }

  // Alternar anclar/desanclar nota
  Future<void> _togglePinNote(Note note) async {
    await StorageService.togglePinned(note);
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
    // Mostrar feedback usando el color de la app
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            note.isPinned
                ? '✓ Desanclado de favoritos'
                : '★ Anclado a favoritos',
          ),
          backgroundColor: note.isPinned
              ? Colors.grey.shade600
              : _appColor.withAlpha(200),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Mostrar menú contextual para nota
  void _showNoteOptions(BuildContext context, Note note) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                note.isPinned ? CupertinoIcons.pin_slash : CupertinoIcons.pin,
                // Usa el color de la app para anclar/desanclar
                color: note.isPinned ? Colors.grey.shade600 : _appColor,
              ),
              title: Text(
                note.isPinned
                    ? 'Desanclar de favoritos'
                    : 'Anclar como favorito',
              ),
              onTap: () {
                Navigator.pop(context);
                _togglePinNote(note);
              },
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.eye),
              title: const Text('Ver nota'),
              onTap: () {
                Navigator.pop(context);
                _navigateToNote(note);
              },
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.trash, color: Colors.red),
              title: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteNote(note);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _deleteNote(Note note) async {
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
      return true;
    }
    return false;
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

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LoginPage(
              currentColorIndex: widget.currentColorIndex,
              onColorChanged: widget.onColorChanged,
            ),
          ),
        );
      }
    }
  }

  void _showConfigSelector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Capturar el índice actual al abrir el diálogo
    final initialIdx = widget.currentColorIndex;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, animation, secondaryAnimation) {
        // Usar el widget separado con estado propio
        return _ColorSelectorWidget(
          initialIndex: initialIdx,
          onColorSelected: widget.onColorChanged,
          colorScheme: colorScheme,
        );
      },
    );
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentColorIndex != widget.currentColorIndex) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSearching = _searchQuery.isNotEmpty;

    // Aplicar filtro de favoritos si está activo
    List<Note> filteredNotes;
    if (_showPinnedOnly) {
      filteredNotes = _notes.where((note) => note.isPinned).toList();
    } else if (isSearching) {
      filteredNotes = _filteredNotes;
    } else {
      filteredNotes = _notes;
    }

    // Ordenar: favoritos primero
    filteredNotes.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return 0;
    });

    final displayNotes = filteredNotes;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis Apuntes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(CupertinoIcons.bars),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Menú',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.gear),
            onPressed: () => _showConfigSelector(context),
            tooltip: 'Configuración',
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 24,
                left: 24,
                right: 24,
                bottom: 24,
              ),
              decoration: BoxDecoration(color: colorScheme.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar del usuario
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white,
                    child: widget.user?.photoURL != null
                        ? ClipOval(
                            child: Image.network(
                              widget.user!.photoURL!,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                CupertinoIcons.person_fill,
                                size: 36,
                                color: colorScheme.primary,
                              ),
                            ),
                          )
                        : Icon(
                            CupertinoIcons.person_fill,
                            size: 36,
                            color: colorScheme.primary,
                          ),
                  ),
                  const SizedBox(height: 16),
                  // Nombre del usuario
                  Text(
                    widget.user?.displayName ?? 'Usuario',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Correo del usuario
                  Text(
                    widget.user?.email ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Botón de cerrar sesión
            ListTile(
              leading: const Icon(CupertinoIcons.square_arrow_right),
              title: const Text('Cerrar Sesión'),
              onTap: _handleSignOut,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
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
                          confirmDismiss: (direction) async {
                            return await _deleteNote(note);
                          },
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
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _navigateToNote(note),
                              onLongPress: () =>
                                  _showNoteOptions(context, note),
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
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
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
                                              // Botón de pin (como WhatsApp) - usa color de la app
                                              GestureDetector(
                                                onTap: () =>
                                                    _togglePinNote(note),
                                                child: Icon(
                                                  note.isPinned
                                                      ? CupertinoIcons.pin_fill
                                                      : CupertinoIcons.pin,
                                                  size: 20,
                                                  color: note.isPinned
                                                      ? _appColor
                                                      : Colors.grey.shade400,
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
      floatingActionButton: SafeArea(
        child: FloatingActionButton(
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
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.plus, size: 20),
              Text('Nueva', style: TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}
