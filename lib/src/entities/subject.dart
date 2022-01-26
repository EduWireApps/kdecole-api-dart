part of kdecole_api;

class Subject {
  final List<Grade> grades;
  final String name;
  final String teacher;
  final double mid;
  final double midClass;

  const Subject({
    required this.grades,
    required this.name,
    required this.mid,
    required this.midClass,
    required this.teacher,
  });
}
