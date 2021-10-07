class HomeWork {
  final String _content;
  final String _type;
  final String _subject;
  final int _estimatedTime;
  final bool _isRealised;
  final int _uuid;
  final int _sessionUuid;
  final DateTime _date;

  HomeWork(this._content, this._type,
      this._subject, this._estimatedTime, this._isRealised, this._uuid, this._sessionUuid, this._date);

  int get sessionUuid => _sessionUuid;

  int get uuid => _uuid;

  bool get isRealised => _isRealised;

  int get estimatedTime => _estimatedTime;

  String get subject => _subject;

  String get type => _type;

  String get content => _content;

  DateTime get date => _date;
}
