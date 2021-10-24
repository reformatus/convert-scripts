import 'dart:io';
import 'package:path/path.dart';

File allTextFile = File("szoveg.txt");
Directory sheetsDir = Directory("sheets");

Map<String, int> letterNum = {'A': 1, 'B': 2, 'C': 3, 'D': 4, 'E': 5, 'F': 6};
Map<int, String> numLetter =
    letterNum.map((key, value) => MapEntry(value, key));

void main(List<String> arguments) {
  List<String> allTextLines = allTextFile.readAsLinesSync();
  List<int> idLines = [];
  List<Verse> verses = [];
  List<Song> songs = [];

  List<Sheet> sheets = [];
  sheetsDir.listSync().forEach((entity) {
    if (entity is File) {
      List<String> data = basename(entity.path)
          .substring(0, basename(entity.path).indexOf(" "))
          .split('-');
      int songId = int.parse(data[0]);

      late int verseId = 1;
      late int index = 1;
      if (data.length == 2) {
        if (data[1].length > 1) {
          //! can get verseid and index too
          if (RegExp(r"[A-Z]").hasMatch(data[1][1])) {
            //! one character verse id, one index
            index = letterNum[data[1][1]]!;
            verseId = int.parse(data[1][0]);
          } else {
            //! both characters verse id
            index = 1;
            verseId = int.parse(data[1]);
          }
        } else {
          if (RegExp(r"[A-Z]").hasMatch(data[1][0])) {
            //! only index is given
            index = letterNum[data[1][0]]!;
            verseId = 1;
          } else {
            //! only verse number is given (not first verse!)
            verseId = int.parse(data[1][0]);
            index = 1;
          }
        }
      } else if (data.length == 3) {
        //! everything is nice and the sun is shining
        verseId = int.parse(data[1]);
        try {
          index = letterNum[data[2]]!;
        } catch (e) {}
      } else {
        verseId = 1;
        index = 1; //! Indexing begins at 1
      }
      sheets.add(Sheet(
          songId, verseId, index, "V$verseId${numLetter[index]}", entity));
    }
  });

  int i = 0;
  for (String line in allTextLines) {
    if (line.contains(RegExp(r"\d+.")) &&
        !allTextLines[i + 1].contains(RegExp(r"\d+."))) {
      idLines.add(i);
    }
    i++;
  }
  i = 0;
  int prevSongID = 0;
  for (int lineID in idLines) {
    List<String> verseLines = [];
    try {
      for (var n = lineID + 1; n <= idLines[i]; n++) {
        verseLines.add(allTextLines[n]);
      }
    } catch (e) {
      print(e);
    }
    String verseLyrics = " " + verseLines.join("\r\n ");
    int songId = 0;
    int verseId = 0;
    if (allTextLines[lineID].contains(":")) {
      songId = int.parse(allTextLines[lineID].split(":")[0]);
      verseId =
          int.parse(allTextLines[lineID].split(":")[1].replaceAll(".", ""));
    } else {
      songId = int.parse(allTextLines[lineID].replaceAll(".", ""));
      verseId = 1;
    }
    if (songId != prevSongID && songId != (prevSongID + 1))
      print("Inconsistency: $songId, $prevSongID");
    prevSongID = songId;
    verses.add(Verse(verseLyrics, songId, verseId));
    i++;
  }
  print("Verses done.");

  for (Verse verse in verses) {
    if (!songs.any((element) => element.id == verse.songId)) {
      songs.add(Song(verse.songId, [verse]));
    } else {
      songs
          .firstWhere((element) => element.id == verse.songId)
          .verses
          .add(verse);
    }
  }
  songs.sort((a, b) => a.id.compareTo(b.id));
  int prevID = 0;
  for (Song song in songs) {
    if (prevID + 1 != song.id) print("Missing song: ${prevID + 1}");
    prevID = song.id;
    String lyrics = "";
    for (Verse verse in song.verses) {
      lyrics += ("[V${verse.verseId}]\r\n" + verse.lyrics + "\r\n");
    }
    song.lyrics = lyrics;

    song.title = ("${song.id}. " + (song.id > 150 ? "Dicséret" : "Zsoltár"));

    song.baseFilename = ("R" +
        song.id.toString().padLeft(3, "0") +
        ". " +
        song.verses[0].lyrics
            .split("\r\n")[0]
            .replaceAll(RegExp(r"[^a-zA-záíűőüöúóéÁÍŰŐÚÜÖÓÓÉ ]"), "")
            .trim());
  }

  print("Songs done.");

  String markdown = "";
  for (Song song in songs) {
    List<Sheet> firstVerseSheets = sheets
        .where((element) => element.songId == song.id && element.verseId == 1)
        .toList();
    markdown += "### ${song.title}\n\n";
    for (Sheet sheet in firstVerseSheets) {
      markdown +=
          '<img src="img/${basename(sheet.file.path)}" loading="lazy">\n';
    }
    for (Verse verse in song.verses) {
      markdown += "\n\n#### ${verse.verseId}. vers\n\n";
      markdown += verse.lyrics.replaceAll("\r\n", "\\\r\n");
    }
    markdown += "\n<hr />\n\n";
  }
  File mdFile = File("markdown.md");
  mdFile.createSync();
  mdFile.writeAsStringSync(markdown);

  print("done");
}

class Verse {
  String lyrics;
  int songId;
  int verseId;
  Verse(this.lyrics, this.songId, this.verseId);
}

class Song {
  int id;
  List<Verse> verses;
  String? title;
  String? baseFilename;
  String? lyrics;
  Song(this.id, this.verses, {this.title, this.baseFilename, this.lyrics});
}

class Sheet {
  int songId;
  int verseId;
  int index;
  String orderToken;
  File file;
  Sheet(this.songId, this.verseId, this.index, this.orderToken, this.file);
}
