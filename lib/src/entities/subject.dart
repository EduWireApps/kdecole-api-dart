part of kdecole_api;

class Subject {
  final List<Grade> grades;
  final String name, teacher;
  final double mid, midClass;

  const Subject({
    required this.grades,
    required this.name,
    required this.mid,
    required this.midClass,
    required this.teacher,
  });
}
