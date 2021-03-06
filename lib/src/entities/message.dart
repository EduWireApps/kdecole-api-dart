part of kdecole_api;

class Message {
  final String sender;
  final String body;
  final DateTime date;

  Message({required this.body, required this.sender, required this.date});

  String get dateAsString => '${date.day}/${date.month}/${date.year} ${date.hour}h${date.minute}';
}
