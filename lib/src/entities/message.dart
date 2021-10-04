class Message{
  final String _expeditor;
  final String _body;
  final DateTime _date;

  Message(this._body, this._expeditor, this._date);

  String get expeditor{
    return _expeditor;
  }
  String get body{
    return _body;
  }
  String get date{
    return '${_date.day}/${_date.month}/${_date.year} ${_date.hour}h${_date.minute}';
  }
}