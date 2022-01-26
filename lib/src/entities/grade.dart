part of kdecole_api;

class Grade {
  final int id, bareme;
  final double grade, medium, best, coef;
  final String name;
  final DateTime date;

  Grade({
    required this.id,
    required this.grade,
    required this.bareme,
    required this.name,
    required this.date,
    required this.medium,
    required this.best,
    required this.coef,
  });
}
