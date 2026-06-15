class Note {
  int? id;
  String title;
  String content;
  String createdAt;
  String? updatedAt;

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }
}
