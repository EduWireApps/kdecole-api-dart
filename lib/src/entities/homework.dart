part of kdecole_api;

class Homework {
  final String content;
  final String type;
  final String subject;
  final int estimatedTime;
  final bool isRealised;
  final int uuid;
  final int sessionUuid;
  final DateTime date;
  final bool isComplete;

  Homework(
      {required this.content,
      required this.type,
      required this.subject,
      required this.estimatedTime,
      required this.isRealised,
      required this.uuid,
      required this.sessionUuid,
      required this.date,
      required this.isComplete});
}
