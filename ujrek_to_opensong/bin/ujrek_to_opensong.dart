import 'dart:io';
import 'package:html/parser.dart' as html;
import 'package:intl/intl.dart';
import 'package:xml/xml.dart';

File lyricsFile = File('ujrek_text.txt');

void main() {
  List<String> sourceLines = [];
  List<ProtoSong> protoSongs = [];

  print('Reading file...');
  sourceLines = lyricsFile.readAsLinesSync();
  print('Read ${sourceLines.length} lines.');

  print('Parsing file...');

  for (String titleLine
      in sourceLines.where((element) => element.startsWith("T"))) {
    List<String> verses = [];

    for (String verseLine
        in sourceLines.sublist(sourceLines.indexOf(titleLine) + 1)) {
      if (verseLine.startsWith("T")) break;
      String verseString =
          html.parse(verseLine.replaceAll("<br>", "\n")).documentElement!.text;

      verses.add(" " +
          (verseString.allMatches("\n").length > 2
                  ? verseString.replaceAll("/ ", "")
                  : verseString.replaceAll("/ ", "\n "))
              .substring(verseString.indexOf(". ") + 2));
    }
    int index = int.parse(titleLine.substring(1, titleLine.indexOf(". ")));

    protoSongs.add(ProtoSong(
        index,
        titleLine.substring(1),
        ('U' +
                NumberFormat("000").format(index) +
                titleLine.substring(titleLine.indexOf(". ")))
            .replaceAll(RegExp(r'[\\/:*?\"<>|]'), ""),
        verses));
  }

  protoSongs.sort((a, b) => a.index.compareTo(b.index));

  print('Parsed ${protoSongs.length} songs.');

  print('Building songs...');
  for (ProtoSong song in protoSongs) {
    print(song.filename);

    String lyrics = "";

    for (String verseString in song.verses) {
      lyrics += ('[V${song.verses.indexOf(verseString) + 1}]\n$verseString' +
          (verseString.substring(verseString.length - 1) == "\n" ? "" : "\n"));
    }

    var builder = XmlBuilder();
    builder.processing('xml', 'version="1.0"');
    builder.element('song', nest: () {
      builder.element('title', nest: () {
        builder.text(song.presentTitle);
      });
      builder.element('lyrics', nest: () {
        builder.text(lyrics);
      });
    });

    File songFile = File('songs\\' + song.filename);
    songFile.createSync(recursive: true);
    songFile.writeAsStringSync(builder.buildDocument().toXmlString(
        pretty: true, indent: "  ", preserveWhitespace: (_) => true));
  }

  print('\nDone.');
}

class ProtoSong {
  String presentTitle;
  String filename;
  int index;
  List<String> verses;

  ProtoSong(this.index, this.presentTitle, this.filename, this.verses);
}
