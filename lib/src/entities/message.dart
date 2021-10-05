class Message{
  final String _sender;
  final String _body;
  final DateTime _date;

  Message(this._body, this._sender, this._date);

  String get sender{
    return _sender;
  }
  String get body{
    return _body;
  }
  String get date{
    return '${_date.day}/${_date.month}/${_date.year} ${_date.hour}h${_date.minute}';
  }
}