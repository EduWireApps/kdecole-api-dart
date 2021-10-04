import 'dart:convert';

import 'package:html/parser.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;
import 'package:kdecole_api/kdecole_api.dart';
import 'package:kdecole_api/src/entities/email.dart';
import 'package:kdecole_api/src/entities/userinfo.dart';
import 'package:request/request.dart';

import 'entities/message.dart';

class Client {
  late final String url;
  Urls urls;
  late String token;
  Map<String, String> header = {};

  Client(this.urls, username, password) {
    url = enumToUrl(urls);
    login(username, password);
  }

  Client.fromToken(this.token, this.urls) {
    url = enumToUrl(urls);
    header.addAll({'X-Kdecole-Auth': token, 'X-Kdecole-Vers': '3.7.14'});
  }

  Future<String> login(String username, String password) async {
    var rep = await invokeApi(url + username + '/' + password, {}, 'GET');
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

  Future<UserInfo> getUserData() async {
    var json = jsonDecode(
        (await invokeApi(url + 'infoutilisateur/', header, 'GET')).body);
    print(json['nom']);
    return UserInfo(json['nom'], json['etabs'][0]['nom']);
  }

  Future<List<Email>?> getEmails() async {
    var convert = HtmlUnescape();
    var json = jsonDecode(
        (await invokeApi(url + 'messagerie/boiteReception/', header, 'GET'))
            .body);
    var emails = json['communications'] as List<dynamic>;
    List<Email> ret = [];
    for (var element in emails) {
      ret.add(Email(
          convert.convert(element['objet']),
          convert.convert(element['premieresLignes']),
          convert.convert(element['expediteurInitial']['libelle']),
          '',
          element['id'], []));
    }
    return ret;
  }

  Future<Email> getFullEmail(Email email) async {
    var messages = <Message>[];
    var json = jsonDecode((await invokeApi(
            url + 'messagerie/communication/' + email.id.toString() + '/',
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
          parsedString,
          element['redacteur']['libelle'],
          DateTime.fromMillisecondsSinceEpoch(
              int.parse(element['dateEnvoi'].toString()))));
    }

    return Email(
        convert.convert(json['objet']),
        convert.convert(json['premieresLignes']),
        convert.convert(json['expediteurInitial']['libelle']),
        convert.convert(json['participants'][0]['libelle']),
        json['id'],
        messages);
  }

  void unlog() async {
    invokeApi(url + 'desactivation/', header, 'GET');
  }

  Future<Response> invokeApi(var url, Map<String, String> headers, var method,
      {var body}) async {
    switch (method) {
      case 'GET':
        return await http.get(Uri.parse(url), headers: headers);
      case 'POST':
        return await http.post(Uri.parse(url), headers: headers, body: body);
      case 'DELETE':
        return await http.delete(Uri.parse(url), headers: headers, body: body);
      case 'PUT':
        return await http.put(Uri.parse(url), headers: headers, body: body);
      case 'PATCH':
        return await http.patch(Uri.parse(url), headers: headers, body: body);
      default:
        return await http.get(Uri.parse(url), headers: headers);
    }
  }

  String enumToUrl(Urls url) {
    switch (url) {
      case Urls.agora06:
        return 'https://mobilite.agora06.fr/mobilite/';
      case Urls.arsene76:
        return 'https://mobilite.arsene76.fr/mobilite/';
      case Urls.auCollege84Vaucluse:
        return 'https://mobilite.aucollege84.vaucluse.fr/mobilite/';
      case Urls.auvergneRhoneAlpes:
        return 'https://mobilite.ent.auvergnerhonealpes.fr/mobilite/';
      case Urls.cyberColleges42:
        return 'https://mobilite.cybercolleges42.fr/mobilite/';
      case Urls.demo:
        return 'https://mobilite.demo.skolengo.com/mobilite/';
      case Urls.eclatBfc:
        return 'https://mobilite.eclat-bfc.fr/mobilite/';
      case Urls.eCollegeHauteGaronne:
        return 'https://mobilite.ecollege.haute-garonne.fr/mobilite/';
      case Urls.ent27:
        return 'https://mobilite.ent27.fr/mobilite/';
      case Urls.entCreuse:
        return 'https://mobilite.entcreuse.fr/mobilite/';
      case Urls.kosmosEducation:
        return 'https://mobilite.kosmoseducation.com/mobilite/';
      case Urls.monBureauNumerique:
        return 'https://mobilite.monbureaunumerique.fr/mobilite/';
      case Urls.monCollegeValdoise:
        return 'https://mobilite.moncollege.valdoise.fr/mobilite/';
      case Urls.monEntOccitanie:
        return 'https://mobilite.mon-ent-occitanie.fr/mobilite/';
      case Urls.savoirsNumeriques62:
        return 'https://mobilite.savoirsnumeriques62.fr/mobilite/';
      case Urls.webCollegeSeineSaintDenis:
        return 'https://mobilite.webcollege.seinesaintdenis.fr/mobilite/';
    }
  }
}

enum Urls {
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
