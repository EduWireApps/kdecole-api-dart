part of kdecole_api;

class Actuality {
  final String author;
  final String title;
  final String uid;
  final String codeEmetteur;
  final DateTime date;
  final String? content;
  final bool isComplete;
  final String type;

  Actuality({
    required this.author,
    required this.title,
    required this.uid,
    required this.codeEmetteur,
    required this.date,
    required this.isComplete,
    required this.type,
    this.content,
  });
}
