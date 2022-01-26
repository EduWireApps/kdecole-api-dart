import 'package:kdecole_api/kdecole_api.dart';

class Period {
  int id;
  String className, periodName;
  List<Subject> subjects;

  Period({
    required this.id,
    required this.className,
    required this.periodName,
    required this.subjects,
  });
}
