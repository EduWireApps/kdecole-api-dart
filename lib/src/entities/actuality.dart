part of kdecole_api;

class Actuality {
  final String author;
  final String title;
  final String uid;
  final String codeEmetteur;
  final DateTime date;
  final String? content;

  Actuality({
    required this.author,
    required this.title,
    required this.uid,
    required this.codeEmetteur,
    required this.date,
    this.content,
  });
}
