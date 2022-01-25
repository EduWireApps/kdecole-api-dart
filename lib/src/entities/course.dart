part of kdecole_api;

class Course {
  final String subject;
  final List homeworks;
  final String content;
  final DateTime startDate;
  final DateTime endDate;

  Course(
      {required this.subject,
      required this.homeworks,
      required this.content,
      required this.startDate,
      required this.endDate});
}
