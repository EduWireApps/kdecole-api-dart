part of kdecole_api;

class Permissions {
  final bool emails;
  final bool marks;
  final bool timetable;
  final bool homeworks;
  final bool schoolLife;

  Permissions({
    required this.emails,
    required this.marks,
    required this.timetable,
    required this.homeworks,
    required this.schoolLife,
  });
}
