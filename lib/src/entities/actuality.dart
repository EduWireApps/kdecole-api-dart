part of kdecole_api;

class Actuality {
  final String author, title, uid, codeEmetteur;
  final String? content;
  final DateTime date;

  Actuality({
    required this.author,
    required this.title,
    required this.uid,
    required this.codeEmetteur,
    required this.date,
    this.content,
  });
}
