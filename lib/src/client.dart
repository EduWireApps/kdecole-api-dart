part of '../kdecole_api.dart';

class Client {
  late final String url;
  late String token;
  late Perms perms;
  Map<String, String> header = {};
  late UserInfo info;

  Client(this.url, username, password) {
    login(username, password);
  }

  ///Create this object if you already have a token
  Client.fromToken(this.token, this.url) {
    header.addAll({'X-Kdecole-Auth': token, 'X-Kdecole-Vers': '3.7.14'});
  }

  Future<void> setUserData() async {
    var json =
        jsonDecode((await _invokeApi('infoutilisateur/', header, 'GET')).body);

    ///bad code, but api bad too
    dynamic a;
    while (true) {
      a = jsonDecode((await _invokeApi(
              'consulterAbsences/idetablissement/${int.parse(json['idEtablissementSelectionne'])}/',
              header,
              'GET'))
          .body);
      if (a['errmsg'] == null) break;
      await Future.delayed(Duration(seconds: 1));
    }
    info = UserInfo(
      fullName: json['nom'],
      etab: json['etabs'][0]['nom'],
      etabId: int.parse(json['idEtablissementSelectionne']),
      id: a['codeEleve'],
    );
    var p = json['etabs'][0]['permissions'].toString().split(' ');
    perms = Perms(
      emails: p.contains('messagerie'),
      marks: p.contains('vsc-releves-consulter'),
      timetable: p.contains('cdt-calendrier'),
      homeworks: p.contains('cdt-travaux'),
      schoolLife: p.contains('vsc-abs-consulter'),
    );
  }

  ///Login with temporary username and password
  Future<String> login(String username, String password) async {
    var rep = await _invokeApi(username + '/' + password, {}, 'GET');
    var json = jsonDecode(rep.body);
    if (json['authtoken'] == null) {
      return 'An error as occured';
    } else {
      token = json['authtoken'];
      header.addAll({'X-Kdecole-Auth': token, 'X-Kdecole-Vers': '3.7.14'});
      return 'Succesfuly connected';
    }
  }

  Future<List<Actuality>> getActualities() async {
    var rep = jsonDecode((await _invokeApi(
            'actualites/idetablissement/${info.etabId}/', header, 'GET'))
        .body);
    var ret = <Actuality>[];
    for (var v in rep) {
      if (v['uid'].toString().contains('-')) {
        ret.add(Actuality(
            author: v['auteur'],
            title: v['titre'],
            uid: v['uid'],
            codeEmetteur: v['codeEmetteur'],
            date: DateTime.fromMillisecondsSinceEpoch(v['date'])));
      }
    }
    return ret;
  }

  Future<Actuality> getFullActuality({required Actuality actuality}) async {
    var json = jsonDecode((await _invokeApi(
            'contenuArticle/article/${actuality.uid}/', header, 'GET'))
        .body);
    return Actuality(
      title: json['titre'],
      date: DateTime.fromMillisecondsSinceEpoch(json['date']),
      author: json['auteur'],
      content:
          parse(HtmlUnescape().convert(json['codeHTML'])).documentElement!.text,
      codeEmetteur: actuality.codeEmetteur,
      uid: actuality.uid,
    );
  }

  Future<List<Grade>> getGrades() async {
    var response = jsonDecode((await _invokeApi(
            'consulterReleves/idetablissement/${info.etabId}/', header, 'GET'))
        .body);
    var ret = <Grade>[];

    for (var v in response[0]['matieres']) {
      for (var l in v['devoirs']) {
        ret.add(Grade(
          id: l['id'],
          grade: l['note'],
          maxGrade: l['bareme'],
          name: l['titreDevoir'],
          date: DateTime.fromMillisecondsSinceEpoch(l['date']),
        ));
      }
    }

    return ret;
  }

  ///To get name, school or class
  UserInfo getUserData() {
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

  ///Get the timetable of the week
  Future<List<Course>> getTimetable() async {
    var json = jsonDecode((await _invokeApi(
            'calendrier/idetablissement/${info.id}/', header, 'GET'))
        .body);
    var ret = <Course>[];
    for (var element in json['listeJourCdt']) {
      for (var e in element['listeSeances']) {
        var hw = [];
        if (e['aRendre'] != null) {
          for (var i in e['aRendre']) {
            hw.add(i['uid']);
          }
        }
        ret.add(Course(
            subject: e['matiere'],
            homeworks: hw,
            content: e['titre'],
            startDate: DateTime.fromMillisecondsSinceEpoch(e['hdeb']),
            endDate: DateTime.fromMillisecondsSinceEpoch(e['hfin'])));
      }
    }
    return ret;
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
}

/// THIS IS A LIST OF ALL THE URLS
/// 
///      agora06
///        https://mobilite.agora06.fr/mobilite/
///      arsene76:
///        https://mobilite.arsene76.fr/mobilite/
///      auCollege84Vaucluse:
///        https://mobilite.aucollege84.vaucluse.fr/mobilite/
///      auvergneRhoneAlpes:
///        https://mobilite.ent.auvergnerhonealpes.fr/mobilite/
///      cyberColleges42:
///        https://mobilite.cybercolleges42.fr/mobilite/
///      demo:
///        https://mobilite.demo.skolengo.com/mobilite/
///      eclatBfc:
///        https://mobilite.eclat-bfc.fr/mobilite/
///      eCollegeHauteGaronne:
///        https://mobilite.ecollege.haute-garonne.fr/mobilite/
///      ent27:
///        https://mobilite.ent27.fr/mobilite/
///      entCreuse:
///        https://mobilite.entcreuse.fr/mobilite/
///      kosmosEducation:
///        https://mobilite.kosmoseducation.com/mobilite/
///      monBureauNumerique:
///        https://mobilite.monbureaunumerique.fr/mobilite/
///      monCollegeValdoise:
///        https://mobilite.moncollege.valdoise.fr/mobilite/
///      monEntOccitanie:
///        https://mobilite.mon-ent-occitanie.fr/mobilite/
///      savoirsNumeriques62:
///        https://mobilite.savoirsnumeriques62.fr/mobilite/
///      webCollegeSeineSaintDenis
///        https://mobilite.webcollege.seinesaintdenis.fr/mobilite/
/// 

