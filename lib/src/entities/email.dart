part of '../../kdecole_api.dart';

class Email {
  final String title;
  final String body;
  final String sender;
  final String receivers;
  final int id;
  final List<Message> messages;

  Email(
      {required this.title,
      required this.body,
      required this.sender,
      required this.receivers,
      required this.id,
      required this.messages});
}
