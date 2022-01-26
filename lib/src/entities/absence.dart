part of kdecole_api;

class Absence {
  final DateTime dateFin;
  final String motif;
  final String type;
  final String matiere;
  final DateTime dateDebut;
  final bool justifiee;

  Absence(
      {required this.dateFin,
      required this.motif,
      required this.type,
      required this.matiere,
      required this.dateDebut,
      required this.justifiee});
}
