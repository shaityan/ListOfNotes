class Note {
  final String title;
  final String text;

  const Note({
    required this.title,
    required this.text,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'text': text,
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      title: json['title'] as String? ?? '',
      text: json['text'] as String? ?? '',
    );
  }
}


