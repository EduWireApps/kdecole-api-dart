part of '../kdecole_api.dart';

class Client {
  late final String url;
  final casUrl urls;
  late String token;
  Map<String, String> header = {};
  late UserInfo info;

  Client(this.urls, username, password) {
    url = _enumToUrl(urls);
    login(username, password);
  }

  ///Create this object if you already have a token
  Client.fromToken(this.token, this.urls) {
    url = _enumToUrl(urls);
    header.addAll({'X-Kdecole-Auth': token, 'X-Kdecole-Vers': '3.7.14'});
  }

  Future<void> setUserData() async {
    var json =
        jsonDecode((await _invokeApi('infoutilisateur/', header, 'GET')).body);
    print(json);
    info = UserInfo(
        fullName: json['nom'],
        etab: json['etabs'][0]['nom'],
        id: int.parse(json['idEtablissementSelectionne']));
  }

  ///Login with temporary username and password
  Future<String> login(String username, String password) async {
    var rep = await _invokeApi(username + '/' + password, {}, 'GET');
    var json = jsonDecode(rep.body);
    print(json['authtoken']);
    if (json['authtoken'] == null) {
      return 'An error as occured';
    } else {
      token = json['authtoken'];
      header.addAll({'X-Kdecole-Auth': token, 'X-Kdecole-Vers': '3.7.14'});
      return 'Succesfuly connected';
    }
  }

  ///To get name, school or class
  Future<UserInfo> getUserData() async {
    return info;
  }

  ///Get the messaging emails, only a preview of them
  Future<List<Email>?> getEmails() async {
    var convert = HtmlUnescape();
    var json = jsonDecode(
        (await _invokeApi('messagerie/boiteReception/', header, 'GET')).body);
    var emails = json['communications'] as List<dynamic>;
    List<Email> ret = [];
    for (var element in emails) {
      ret.add(Email(
          title: convert.convert(element['objet']),
          body: convert.convert(element['premieresLignes']),
          sender: convert.convert(element['expediteurInitial']['libelle']),
          receivers: '',
          id: element['id'],
          messages: []));
    }
    return ret;
  }

  ///Get all the details of an Email, with the full body
  Future<Email> getFullEmail(Email email) async {
    var messages = <Message>[];
    var json = jsonDecode((await _invokeApi(
            'messagerie/communication/' + email.id.toString() + '/',
            header,
            'GET'))
        .body);
    var convert = HtmlUnescape();
    var messagesList = json['participations'] as List<dynamic>;
    for (var element in messagesList) {
      print(element);

      final String parsedString =
          parse(convert.convert(element['corpsMessage'])).documentElement!.text;
      messages.add(Message(
          body: parsedString,
          sender: element['redacteur']['libelle'],
          date: DateTime.fromMillisecondsSinceEpoch(
              int.parse(element['dateEnvoi'].toString()))));
    }

    return Email(
        title: convert.convert(json['objet']),
        body: convert.convert(json['premieresLignes']),
        sender: convert.convert(json['expediteurInitial']['libelle']),
        receivers: convert.convert(json['participants'][0]['libelle']),
        id: json['id'],
        messages: messages);
  }

  ///Send an email
  Future<void> sendEmail(String body, Email emailToRespond) async {
    await _invokeApi(
        'messagerie/communication/nouvelleParticipation/${emailToRespond.id}/',
        header,
        'PUT',
        body: body);
  }

  ///Mark as read an Email
  Future<void> markAsRead(Email mail) async {
    await _invokeApi('messagerie/communication/lu/${mail.id}/', header, 'PUT');
  }

  ///Delete communication
  Future<void> deleteMail(Email mail) async {
    await _invokeApi(
        'messagerie/communication/supprimer/${mail.id}/', header, 'DELETE');
  }

  ///Report an email, don't abuse of it
  Future<void> reportMail(Email mail) async {
    await _invokeApi(
        'messagerie/communication/signaler/${mail.id}/', header, 'PUT');
  }

  ///Get the homeworks
  Future<List<HomeWork>> getHomeworks() async {
    var json = jsonDecode((await _invokeApi(
            'travailAFaire/idetablissement/${info.id}/', header, 'GET'))
        .body);
    print(json);
    var homeworks = json['listeTravaux'] as List<dynamic>;
    var ret = <HomeWork>[];
    for (var element in homeworks) {
      var date = DateTime.fromMillisecondsSinceEpoch(element['date']);
      for (var e in element['listTravail']) {
        ret.add(HomeWork(
            content: e['titre'],
            type: e['type'],
            subject: e['matiere'],
            estimatedTime: e['temps'],
            isRealised: e['flagRealise'],
            uuid: int.parse(e['uid']),
            sessionUuid: int.parse(e['uidSeance']),
            date: date));
      }
    }

    return ret;
  }

  ///Get all the details of a Homework
  Future<HomeWork> getFullHomework(HomeWork hw) async {
    var convert = HtmlUnescape();
    var json = jsonDecode((await _invokeApi(
            'contenuActivite/idetablissement/${info.id}/${hw.sessionUuid}/${hw.uuid}/',
            header,
            'GET'))
        .body);
    print(json);
    final String parsedString =
        parse(convert.convert(json['codeHTML'])).documentElement!.text;
    return HomeWork(
        content: parsedString,
        type: json['type'],
        subject: json['matiere'],
        estimatedTime: hw.estimatedTime,
        isRealised: json['flagRealise'],
        uuid: hw.uuid,
        sessionUuid: hw.sessionUuid,
        date: DateTime.fromMillisecondsSinceEpoch(json['date']));
  }

  ///To mark an homework as done or not
  ///A full hw (got by the getFullHomework() method isn't needed
  Future<void> setHomeWorkStatus(HomeWork hw, bool newState) async {
    var json = (await _invokeApi(
            'contenuActivite/idetablissement/${info.id}/${hw.sessionUuid}/${hw.uuid}/',
            header,
            'PUT',
            body: '{"flagRealise":$newState}'))
        .body;
    print(json);
  }

  ///To unlog you, you need to re-get a token after that
  void logout() async {
    _invokeApi('desactivation/', header, 'GET');
  }

  Future<Response> _invokeApi(var path, Map<String, String> header, var method,
      {var body}) async {
    var _url = url + path;
    switch (method) {
      case 'GET':
        return await http.get(Uri.parse(_url), headers: header);
      case 'POST':
        return await http.post(Uri.parse(_url), headers: header, body: body);
      case 'DELETE':
        return await http.delete(Uri.parse(_url), headers: header, body: body);
      case 'PUT':
        return await http.put(Uri.parse(_url), headers: header, body: body);
      case 'PATCH':
        return await http.patch(Uri.parse(_url), headers: header, body: body);
      default:
        return await http.get(Uri.parse(_url), headers: header);
    }
  }

  String _enumToUrl(casUrl url) {
    switch (url) {
      case casUrl.agora06:
        return 'https://mobilite.agora06.fr/mobilite/';
      case casUrl.arsene76:
        return 'https://mobilite.arsene76.fr/mobilite/';
      case casUrl.auCollege84Vaucluse:
        return 'https://mobilite.aucollege84.vaucluse.fr/mobilite/';
      case casUrl.auvergneRhoneAlpes:
        return 'https://mobilite.ent.auvergnerhonealpes.fr/mobilite/';
      case casUrl.cyberColleges42:
        return 'https://mobilite.cybercolleges42.fr/mobilite/';
      case casUrl.demo:
        return 'https://mobilite.demo.skolengo.com/mobilite/';
      case casUrl.eclatBfc:
        return 'https://mobilite.eclat-bfc.fr/mobilite/';
      case casUrl.eCollegeHauteGaronne:
        return 'https://mobilite.ecollege.haute-garonne.fr/mobilite/';
      case casUrl.ent27:
        return 'https://mobilite.ent27.fr/mobilite/';
      case casUrl.entCreuse:
        return 'https://mobilite.entcreuse.fr/mobilite/';
      case casUrl.kosmosEducation:
        return 'https://mobilite.kosmoseducation.com/mobilite/';
      case casUrl.monBureauNumerique:
        return 'https://mobilite.monbureaunumerique.fr/mobilite/';
      case casUrl.monCollegeValdoise:
        return 'https://mobilite.moncollege.valdoise.fr/mobilite/';
      case casUrl.monEntOccitanie:
        return 'https://mobilite.mon-ent-occitanie.fr/mobilite/';
      case casUrl.savoirsNumeriques62:
        return 'https://mobilite.savoirsnumeriques62.fr/mobilite/';
      case casUrl.webCollegeSeineSaintDenis:
        return 'https://mobilite.webcollege.seinesaintdenis.fr/mobilite/';
    }
  }
}

///List of cas' urls
enum casUrl {
  monBureauNumerique,
  monEntOccitanie,
  arsene76,
  ent27,
  entCreuse,
  auvergneRhoneAlpes,
  savoirsNumeriques62,
  agora06,
  cyberColleges42,
  eCollegeHauteGaronne,
  monCollegeValdoise,
  webCollegeSeineSaintDenis,
  eclatBfc,
  kosmosEducation,
  auCollege84Vaucluse,
  demo,
}
