part of kdecole_api;

class Grade {
  final int id;
  final int bareme;
  final double grade;
  final double medium;
  final double best;
  final double coefficient;
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
    required this.coefficient,
  });
}
