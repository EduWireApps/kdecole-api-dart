part of kdecole_api;

class Period {
  final int id;
  final String className;
  final String periodName;
  final List<Subject> subjects;

  Period({
    required this.id,
    required this.className,
    required this.periodName,
    required this.subjects,
  });
}
