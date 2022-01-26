part of kdecole_api;

/// The dart client  for the kdecole Api.
class Client {
  final String url;
  String token = "";
  late Perms perms;
  final Map<String, String> headers = {};
  late UserInfo info;

  Client({required this.url, required String username, required String password}) {
    login(username, password);
  }

  /// Create a new client from a token instead of credentials.
  Client.fromToken({required this.token, required this.url}) {
    headers.addAll({'X-Kdecole-Auth': token, 'X-Kdecole-Vers': '3.7.14'});
  }

  Future<void> setUserData() async {
    final Map<String, dynamic> json = jsonDecode((await _invokeApi('infoutilisateur/', 'GET')).body);

    ///bad code, but api bad too
    Map<String, dynamic> res = {};
    bool continueLoop = true;
    while (continueLoop) {
      res = jsonDecode((await _invokeApi(
              'consulterAbsences/idetablissement/${int.parse(json['idEtablissementSelectionne'])}/', 'GET'))
          .body);
      if (res['errmsg'] == null) {
        continueLoop = false;
      }

      await Future.delayed(Duration(seconds: 1));
    }
    info = UserInfo(
      fullName: json['nom'],
      etab: json['etabs'][0]['nom'],
      etabId: int.parse(json['idEtablissementSelectionne']),
      id: res['codeEleve'],
    );
    final List<String> p = json['etabs'][0]['permissions'].toString().split(' ');
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
    final Response res = await _invokeApi(username + '/' + password, 'GET', headers: {});
    final Map<String, dynamic> json = jsonDecode(res.body);
    if (json['authtoken'] == null) {
      return 'An error as occured';
    } else {
      token = json['authtoken'];
      headers.addAll({'X-Kdecole-Auth': token, 'X-Kdecole-Vers': '3.7.14'});
      return 'Successfully connected';
    }
  }

  Future<List<Actuality>> getActualities() async {
    final List<Map<String, dynamic>> res =
        jsonDecode((await _invokeApi('actualites/idetablissement/${info.etabId}/', 'GET')).body);
    final List<Actuality> actualities = [];
    for (final actuality in res) {
      if (actuality['uid'].toString().contains('-')) {
        actualities.add(Actuality(
            author: actuality['auteur'],
            title: actuality['titre'],
            uid: actuality['uid'],
            codeEmetteur: actuality['codeEmetteur'],
            date: DateTime.fromMillisecondsSinceEpoch(actuality['date'])));
      }
    }
    return actualities;
  }

  Future<List<Absence>> getAbsences() async {
    final List<Map<String, dynamic>> res = jsonDecode(
        (await _invokeApi('consulterAbsences/idetablissement/${info.etabId}/', 'GET')).body)['listeAbsences'];
    final List<Absence> absences = [];
    for (final absence in res) {
      absences.add(Absence(
          dateFin: DateTime.fromMillisecondsSinceEpoch(absence['dateFin']),
          motif: absence['motif'] ?? '',
          type: absence['type'],
          matiere: absence['matiere'],
          dateDebut: DateTime.fromMillisecondsSinceEpoch(absence['dateDebut']),
          justifiee: absence['justifiee']));
    }
    return absences;
  }

  Future<Actuality> getFullActuality({required Actuality actuality}) async {
    var json = jsonDecode((await _invokeApi('contenuArticle/article/${actuality.uid}/', 'GET')).body);
    return Actuality(
      title: json['titre'],
      date: DateTime.fromMillisecondsSinceEpoch(json['date']),
      author: json['auteur'],
      content: parse(HtmlUnescape().convert(json['codeHTML'])).documentElement!.text,
      codeEmetteur: actuality.codeEmetteur,
      uid: actuality.uid,
    );
  }

  Future<List<Period>> getGrades() async {
    var response = jsonDecode((await _invokeApi('consulterReleves/idetablissement/${info.etabId}/', 'GET')).body);
    var ret = <Period>[];
    for (var j in response) {
      var sub = <Subject>[];
      for (var v in j['matieres']) {
        var grades = <Grade>[];
        for (var l in v['devoirs']) {
          grades.add(
            Grade(
              id: l['id'],
              grade: l['note'],
              bareme: l['bareme'],
              name: l['titreDevoir'],
              date: DateTime.fromMillisecondsSinceEpoch(l['date']),
              medium: double.parse(l['moyenne']),
              coef: l['coefficient'],
              best: double.parse(l['noteMax']),
            ),
          );
          sub.add(
            Subject(
              grades: grades,
              name: v['matiereLibelle'],
              mid: double.parse(v['moyenneEleve']),
              midClass: double.parse(v['moyenneClasse']),
              teacher: v['enseignants'][0],
            ),
          );
        }
      }
      ret.add(
        Period(
          className: j['libelleClasse'],
          id: j['idPeriode'],
          periodName: j['periodeLibelle'],
          subjects: sub,
        ),
      );
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
    var json = jsonDecode((await _invokeApi('messagerie/boiteReception/', 'GET')).body);
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
    var json = jsonDecode((await _invokeApi('messagerie/communication/' + email.id.toString() + '/', 'GET')).body);
    var convert = HtmlUnescape();
    var messagesList = json['participations'] as List<dynamic>;
    for (var element in messagesList) {
      final String parsedString = parse(convert.convert(element['corpsMessage'])).documentElement!.text;
      messages.add(Message(
          body: parsedString,
          sender: element['redacteur']['libelle'],
          date: DateTime.fromMillisecondsSinceEpoch(int.parse(element['dateEnvoi'].toString()))));
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
    await _invokeApi('messagerie/communication/nouvelleParticipation/${emailToRespond.id}/', 'PUT', body: body);
  }

  ///Mark as read an Email
  Future<void> markAsRead(Email mail) async {
    await _invokeApi('messagerie/communication/lu/${mail.id}/', 'PUT');
  }

  ///Delete communication
  Future<void> deleteMail(Email mail) async {
    await _invokeApi('messagerie/communication/supprimer/${mail.id}/', 'DELETE');
  }

  ///Report an email, don't abuse of it
  Future<void> reportMail(Email mail) async {
    await _invokeApi('messagerie/communication/signaler/${mail.id}/', 'PUT');
  }

  ///Get the homeworks
  Future<List<HomeWork>> getHomeworks() async {
    var json = jsonDecode((await _invokeApi('travailAFaire/idetablissement/${info.id}/', 'GET')).body);
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
    var json = jsonDecode(
        (await _invokeApi('contenuActivite/idetablissement/${info.id}/${hw.sessionUuid}/${hw.uuid}/', 'GET')).body);
    print(json);
    final String parsedString = parse(convert.convert(json['codeHTML'])).documentElement!.text;
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
    var json = jsonDecode((await _invokeApi('calendrier/idetablissement/${info.id}/', 'GET')).body);
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
    var json = (await _invokeApi('contenuActivite/idetablissement/${info.id}/${hw.sessionUuid}/${hw.uuid}/', 'PUT',
            body: '{"flagRealise":$newState}'))
        .body;
  }

  ///To unlog you, you need to re-get a token after that
  void logout() async {
    _invokeApi('desactivation/', 'GET');
  }

  Future<Response> _invokeApi(String path, String method, {Map<String, String>? headers, Object? body}) async {
    final Uri uri = Uri.parse(url + path);
    headers ??= this.headers;
    switch (method) {
      case 'GET':
        return await http.get(uri, headers: headers);
      case 'POST':
        return await http.post(uri, headers: headers, body: body);
      case 'DELETE':
        return await http.delete(uri, headers: headers, body: body);
      case 'PUT':
        return await http.put(uri, headers: headers, body: body);
      case 'PATCH':
        return await http.patch(uri, headers: headers, body: body);
      default:
        return await http.get(uri, headers: headers);
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

