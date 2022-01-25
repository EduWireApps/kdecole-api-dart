part of kdecole_api;

class Grade {
  final int id, grade, maxGrade;
  final String name;
  final DateTime date;

  Grade({
    required this.id,
    required this.grade,
    required this.maxGrade,
    required this.name,
    required this.date,
  });
}
