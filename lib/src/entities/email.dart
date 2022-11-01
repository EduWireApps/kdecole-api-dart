part of kdecole_api;

class Email {
  final String title;
  final String body;
  final String sender;
  final List<String> receivers;
  final int id;
  final List<Message> messages;
  final bool read;
  final bool isComplete;

  Email(
      {required this.title,
      required this.body,
      required this.sender,
      required this.receivers,
      required this.id,
      required this.messages,
      required this.read,
      required this.isComplete});
}
