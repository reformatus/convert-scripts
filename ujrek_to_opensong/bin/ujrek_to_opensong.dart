import 'dart:io';
import 'package:html/parser.dart' as html;
import 'package:intl/intl.dart';
import 'package:xml/xml.dart';
import 'package:path/path.dart';
import 'dart:convert';

File lyricsFile = File('ujrek_text.txt');
List<String> letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K'];

void main() {
  List<String> sourceLines = [];
  List<ProtoSong> protoSongs = [];
  List<Sheet> sheets = [];

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

  print('Parsing sheets...');

  for (File sheetFile in Directory("sheets").listSync().whereType<File>()) {
    String basename = basenameWithoutExtension(sheetFile.path);
    sheets.add(Sheet(
        sheetFile,
        int.parse(basename.substring(1, basename.indexOf("-"))),
        int.parse(basename.substring(basename.indexOf('-') + 1))));
  }

  print('Building songs...');

  for (ProtoSong song in protoSongs) {
    print(song.filename);

    String lyrics = "";
    String presentationOrder = "";

    List<Sheet> songSheets =
        sheets.where((element) => element.songID == song.index).toList();

    for (Sheet sheet in songSheets) {
      lyrics +=
          "[V1${letters[songSheets.indexOf(sheet)]}]\n ${sheet.songID}-${sheet.sheetID}\n";
      presentationOrder += "V1${letters[songSheets.indexOf(sheet)]} ";
    }

    for (String verseString in song.verses) {
      lyrics += ('[V${song.verses.indexOf(verseString) + 1}]\n$verseString' +
          (verseString.substring(verseString.length - 1) == "\n" ? "" : "\n"));
      if (song.verses.indexOf(verseString) != 0) {
        presentationOrder += "V${song.verses.indexOf(verseString) + 1} ";
      }
    }

    presentationOrder = presentationOrder.trim();

    //! Build XML

    var builder = XmlBuilder();
    builder.processing('xml', 'version="1.0"');
    builder.element('song', nest: () {
      builder.element('title', nest: () {
        builder.text(song.presentTitle);
      });
      builder.element('presentation', nest: () {
        builder.text(presentationOrder);
      });
      builder.element('lyrics', nest: () {
        builder.text(lyrics);
      });
      builder.element('backgrounds', nest: () {
        builder.attribute('resize', 'body');
        builder.attribute('keep_aspect', 'true');
        builder.attribute('link', 'false');
        builder.attribute('background_as_text', 'true');

        for (Sheet sheet in songSheets) {
          builder.element('background', nest: () {
            builder.attribute(
                'verse', "V1${letters[songSheets.indexOf(sheet)]}");
            builder.element('image', nest: () {
              builder.text(base64Encode(sheet.file.readAsBytesSync()));
            });
          });
        }
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

class Sheet {
  File file;
  int songID;
  int sheetID;
  Sheet(this.file, this.songID, this.sheetID);
}
