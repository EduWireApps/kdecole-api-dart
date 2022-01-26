part of kdecole_api;

class Period {
  int id;
  String className;
  String periodName;
  List<Subject> subjects;

  Period({
    required this.id,
    required this.className,
    required this.periodName,
    required this.subjects,
  });
}
