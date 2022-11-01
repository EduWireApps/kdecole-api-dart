part of kdecole_api;

/// The dart client  for the kdecole Api.
class Client {
  final String url;
  String token = "";
  late Permissions permissions;
  final Map<String, String> headers = {};
  late UserInfo info;

  Client(
      {required this.url, required String username, required String password}) {
    login(username, password);
  }

  /// Create a new client from a token instead of credentials.
  Client.fromToken({required this.token, required this.url}) {
    headers.addAll({'X-Kdecole-Auth': token, 'X-Kdecole-Vers': '3.7.14'});
  }

  Future<void> setUserData() async {
    final Map<String, dynamic> json =
        jsonDecode((await _invokeApi('infoutilisateur/', 'GET')).body);

    ///bad code, but api bad too
    Map<String, dynamic> res = {};
    bool continueLoop = true;
    while (continueLoop) {
      res = jsonDecode((await _invokeApi(
              'consulterAbsences/idetablissement/${int.parse(json['idEtablissementSelectionne'])}/',
              'GET'))
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
    final List<String> p =
        json['etabs'][0]['permissions'].toString().split(' ');
    permissions = Permissions(
      emails: p.contains('messagerie'),
      marks: p.contains('vsc-releves-consulter'),
      timetable: p.contains('cdt-calendrier'),
      homeworks: p.contains('cdt-travaux'),
      schoolLife: p.contains('vsc-abs-consulter'),
    );
  }

  ///Login with temporary username and password
  Future<String> login(String username, String password) async {
    final Response res =
        await _invokeApi(username + '/' + password, 'GET', headers: {});
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
    final List<Map<String, dynamic>> res = jsonDecode(
        (await _invokeApi('actualites/idetablissement/${info.etabId}/', 'GET'))
            .body);
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
    final List<Map<String, dynamic>> res = jsonDecode((await _invokeApi(
            'consulterAbsences/idetablissement/${info.etabId}/', 'GET'))
        .body)['listeAbsences'];
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
    final Map<String, dynamic> json = jsonDecode(
        (await _invokeApi('contenuArticle/article/${actuality.uid}/', 'GET'))
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

  Future<List<Period>> getGrades() async {
    final List<Map<String, dynamic>> res = jsonDecode((await _invokeApi(
            'consulterReleves/idetablissement/${info.etabId}/', 'GET'))
        .body);
    final List<Period> periods = [];
    for (final period in res) {
      final List<Subject> subjects = [];
      for (final subject in period['matieres']) {
        final List<Grade> grades = [];
        for (final grade in subject['devoirs']) {
          grades.add(
            Grade(
              id: grade['id'],
              grade: grade['note'],
              bareme: grade['bareme'],
              name: grade['titreDevoir'],
              date: DateTime.fromMillisecondsSinceEpoch(grade['date']),
              medium: double.parse(grade['moyenne']),
              coefficient: grade['coefficient'],
              best: double.parse(grade['noteMax']),
            ),
          );
          subjects.add(
            Subject(
              grades: grades,
              name: subject['matiereLibelle'],
              mid: double.parse(subject['moyenneEleve']),
              midClass: double.parse(subject['moyenneClasse']),
              teacher: subject['enseignants'][0],
            ),
          );
        }
      }
      periods.add(
        Period(
          className: period['libelleClasse'],
          id: period['idPeriode'],
          periodName: period['periodeLibelle'],
          subjects: subjects,
        ),
      );
    }

    return periods;
  }

  ///Get the messaging emails, only a preview of them
  Future<List<Email>> getEmails() async {
    final HtmlUnescape convert = HtmlUnescape();
    final Map<String, dynamic> json = jsonDecode(
        (await _invokeApi('messagerie/boiteReception/', 'GET')).body);
    final List<Email> emails = [];
    for (final email in json['communications'] as List<dynamic>) {
      emails.add(Email(
          title: convert.convert(email['objet']),
          body: convert.convert(email['premieresLignes']),
          sender: convert.convert(email['expediteurInitial']['libelle']),
          receivers: [],
          id: email['id'],
          messages: [],
          read: email['etatLecture']));
    }
    return emails;
  }

  ///Get all the details of an Email, with the full body
  Future<Email> getFullEmail(Email email) async {
    final List<Message> messages = [];
    final List<String> receivers = [];
    final Map<String, dynamic> json = jsonDecode((await _invokeApi(
            'messagerie/communication/' + email.id.toString() + '/', 'GET'))
        .body);
    final HtmlUnescape convert = HtmlUnescape();
    for (final message in json['participations'] as List<dynamic>) {
      final String parsedString =
          parse(convert.convert(message['corpsMessage'])).documentElement!.text;
      messages.add(Message(
          body: parsedString,
          sender: message['redacteur']['libelle'],
          date: DateTime.fromMillisecondsSinceEpoch(
              int.parse(message['dateEnvoi'].toString()))));
    }
    for (final r in json['participants']) {
      receivers.add(convert.convert(r['libelle']));
    }

    return Email(
        title: convert.convert(json['objet']),
        body: convert.convert(json['premieresLignes']),
        sender: convert.convert(json['expediteurInitial']['libelle']),
        receivers: receivers,
        id: json['id'],
        messages: messages,
        read: json['etatLecture']);
  }

  ///Send an email
  Future<void> sendEmail(String body, Email email) async {
    await _invokeApi(
        'messagerie/communication/nouvelleParticipation/${email.id}/', 'PUT',
        body: body);
  }

  ///Mark as read an Email
  Future<void> markAsRead(Email email) async {
    await _invokeApi('messagerie/communication/lu/${email.id}/', 'PUT');
  }

  ///Delete communication
  Future<void> deleteMail(Email email) async {
    await _invokeApi(
        'messagerie/communication/supprimer/${email.id}/', 'DELETE');
  }

  ///Report an email, don't abuse of it
  Future<void> reportMail(Email email) async {
    await _invokeApi('messagerie/communication/signaler/${email.id}/', 'PUT');
  }

  ///Get the homeworks
  Future<List<Homework>> getHomeworks() async {
    final Map<String, dynamic> json = jsonDecode(
        (await _invokeApi('travailAFaire/idetablissement/${info.id}/', 'GET'))
            .body);
    final List<Homework> homeworks = [];
    for (final homework in json['listeTravaux'] as List<dynamic>) {
      var date = DateTime.fromMillisecondsSinceEpoch(homework['date']);
      for (var e in homework['listTravail']) {
        homeworks.add(Homework(
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

    return homeworks;
  }

  ///Get all the details of a Homework
  Future<Homework> getFullHomework(Homework homework) async {
    final HtmlUnescape convert = HtmlUnescape();
    final Map<String, dynamic> json = jsonDecode((await _invokeApi(
            'contenuActivite/idetablissement/${info.id}/${homework.sessionUuid}/${homework.uuid}/',
            'GET'))
        .body);
    print(json);
    final String parsedString =
        parse(convert.convert(json['codeHTML'])).documentElement!.text;
    return Homework(
        content: parsedString,
        type: json['type'],
        subject: json['matiere'],
        estimatedTime: homework.estimatedTime,
        isRealised: json['flagRealise'],
        uuid: homework.uuid,
        sessionUuid: homework.sessionUuid,
        date: DateTime.fromMillisecondsSinceEpoch(json['date']));
  }

  ///Get the timetable of the week
  Future<List<Course>> getTimetable() async {
    final Map<String, dynamic> json = jsonDecode(
        (await _invokeApi('calendrier/idetablissement/${info.id}/', 'GET'))
            .body);
    final List<Course> courses = [];
    for (final day in json['listeJourCdt']) {
      for (final course in day['listeSeances']) {
        final List<dynamic> homeworks = [];
        if (course['aRendre'] != null) {
          for (final homework in course['aRendre']) {
            homeworks.add(homework['uid']);
          }
        }
        courses.add(Course(
            subject: course['matiere'],
            homeworks: homeworks,
            content: course['titre'],
            startDate: DateTime.fromMillisecondsSinceEpoch(course['hdeb']),
            endDate: DateTime.fromMillisecondsSinceEpoch(course['hfin'])));
      }
    }
    return courses;
  }

  ///To mark an homework as done or not
  ///A full hw (got by the getFullHomework() method isn't needed
  Future<void> setHomeworkStatus(Homework homework, bool status) async {
    var json = (await _invokeApi(
            'contenuActivite/idetablissement/${info.id}/${homework.sessionUuid}/${homework.uuid}/',
            'PUT',
            body: '{"flagRealise":$status}'))
        .body;
  }

  ///To unlog you, you need to re-get a token after that
  void logout() async {
    _invokeApi('desactivation/', 'GET');
  }

  Future<Response> _invokeApi(String path, String method,
      {Map<String, String>? headers, Object? body}) async {
    final Uri uri = Uri.parse(url + path);
    headers ??= this.headers;
    switch (method) {
      case 'GET':
        return await get(uri, headers: headers);
      case 'POST':
        return await post(uri, headers: headers, body: body);
      case 'DELETE':
        return await delete(uri, headers: headers, body: body);
      case 'PUT':
        return await put(uri, headers: headers, body: body);
      case 'PATCH':
        return await patch(uri, headers: headers, body: body);
      default:
        return await get(uri, headers: headers);
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

