class UserInfo{

  final String _fullName;
  final String _etab;
  final int _id;

  UserInfo(this._fullName, this._etab, this._id);

  String get name{
    return _fullName;
  }
  String get establishment{
    return _etab;
  }
  int get id{
    return _id;
  }
}