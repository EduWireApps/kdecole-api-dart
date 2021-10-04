class UserInfo{

  var fullName;
  var etab;

  UserInfo(this.fullName, this.etab);

  String get name{
    return fullName;
  }
  String get establishment{
    return etab;
  }
}