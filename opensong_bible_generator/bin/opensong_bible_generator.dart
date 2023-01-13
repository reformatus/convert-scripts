import 'dart:io';

//import 'downloader/szentirashu.dart' as szentirashu;
//import 'downloader/onlinebibliaro.dart' as onlinebibliaro;
import 'downloader/biblegateway.dart' as biblegateway;

import 'package:xml/xml.dart' as xml;

File revidealtKaroliFile = File('Egyszerű fordítás');

void main(List<String> arguments) async {
  //var books = await onlinebibliaro.getBooksFor(4); // Revideált károli
  var books = await biblegateway
      .getBooksFor("Hungarian-Bible-Easy-to-Read-Version-ERV-HU"); // EFO

  var builder = xml.XmlBuilder();
  builder.declaration(encoding: 'UTF-8');
  builder.element('bible', nest: () {
    for (var book in books) {
      builder.element('b', attributes: {"n": book.name}, nest: () {
        for (var chapter in book.chapters!) {
          builder.element('c', attributes: {"n": chapter.num.toString()},
              nest: () {
            for (var verse in chapter.verses) {
              builder.element('v',
                  attributes: {"n": verse.num.toString()}, nest: verse.text);
            }
          });
        }
      });
    }
  });

  revidealtKaroliFile.createSync();
  revidealtKaroliFile
      .writeAsStringSync(builder.buildDocument().toXmlString(pretty: true));
}
