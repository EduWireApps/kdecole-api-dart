import 'message.dart';

class Email{
  final String _title;
  final String _body;
  final String _sender;
  final String _receivers;
  final int _id;
  final List<Message> _messages;
  Email(this._title, this._body, this._sender, this._receivers, this._id, this._messages);

  String get title {
    return _title;
  }
  String get body {
    return _body;
  }
  String get sender {
    return _sender;
  }
  String get receveirs {
    return _receivers;
  }
  int get id{
    return _id;
  }
  List<Message> get messages{
    return _messages;
  }
}