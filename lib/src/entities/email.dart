import 'message.dart';

class Email{
  var _title;
  var _body;
  var _sender;
  var _receivers;
  var _id;
  var _messages;
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