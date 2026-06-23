class Note {
  int? id;
  String title;
  String content;
  String createdAt;
  String? updatedAt;
  String? userId; // ID del usuario en Firebase (Google UID o email)
  String? firestoreId; // ID del documento en Firestore
  String? syncStatus; // 'local', 'synced', 'pending'
  bool isPinned; // Nota anclada como favorito

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.userId,
    this.firestoreId,
    this.syncStatus,
    this.isPinned = false,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'content': content,
      'created_at': createdAt,
    };
    // Solo agregar id si no es null (para update)
    if (id != null) map['id'] = id;
    // Solo agregar campos no nulos para SQLite
    if (updatedAt != null) map['updated_at'] = updatedAt;
    if (userId != null) map['user_id'] = userId;
    if (firestoreId != null) map['firestore_id'] = firestoreId;
    if (syncStatus != null) map['sync_status'] = syncStatus;
    map['is_pinned'] = isPinned ? 1 : 0;
    return map;
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
      userId: map['user_id'],
      firestoreId: map['firestore_id'],
      syncStatus: map['sync_status'],
      isPinned: map['is_pinned'] == 1,
    );
  }

  // Convertir a mapa para Firestore (sin el ID local)
  Map<String, dynamic> toFirestoreMap() {
    return {
      'title': title,
      'content': content,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'userId': userId,
      'isPinned': isPinned,
    };
  }

  // Crear desde documento de Firestore
  factory Note.fromFirestoreMap(String docId, Map<String, dynamic> map) {
    return Note(
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdAt: map['createdAt'] ?? DateTime.now().toIso8601String(),
      updatedAt: map['updatedAt'],
      userId: map['userId'],
      firestoreId: docId,
      syncStatus: 'synced',
      isPinned: map['isPinned'] ?? false,
    );
  }

  // Crear copia con cambios
  Note copyWith({
    int? id,
    String? title,
    String? content,
    String? createdAt,
    String? updatedAt,
    String? userId,
    String? firestoreId,
    String? syncStatus,
    bool? isPinned,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      firestoreId: firestoreId ?? this.firestoreId,
      syncStatus: syncStatus ?? this.syncStatus,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}
