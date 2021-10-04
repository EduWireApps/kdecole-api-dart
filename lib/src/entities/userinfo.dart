class UserInfo{

  final String fullName;
  final String etab;

  UserInfo(this.fullName, this.etab);

  String get name{
    return fullName;
  }
  String get establishment{
    return etab;
  }
}