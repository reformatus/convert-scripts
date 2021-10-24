import 'dart:io';
import 'package:path/path.dart';

List<int> tooLong = [];
List<int> hadError = [];

void main(List<String> arguments) {
  Directory songsDir = Directory("Songs");

  //Iterate trough folder of songs
  for (File file in songsDir.listSync()) {
    Song song = getSong(file);

    if (song.lyrics != null) {
      var parts = file.readAsStringSync().split("<lyrics>");
      parts[1] = parts[1].substring(parts[1].indexOf("</lyrics>"));

      String nLyrics = "";
      for (var verse in getVerses(song)) {
        nLyrics += (verse.id + "\n");
        for (var line in verse.lines) {
          nLyrics += (line + "\n");
        }
      }

      String nSongString = parts[0] + "<lyrics>" + nLyrics + parts[1];
      File nSong = new File("NewSongs/" + basename(file.path));
      nSong.writeAsStringSync(nSongString);

      print(song.id.toString() + " OK");
      //break;
    } else {
      print(song.id.toString() + " already done manually");
    }
  }

  //Finish report:

  print("\n -------------------\nHad errors: ");
  File errorsFile = new File("NewSongs/_errors.txt");
  String errorsStr = "";
  for (var id in hadError) {
    print(id);
    errorsStr += (id.toString() + "\n");
  }
  errorsFile.writeAsStringSync(errorsStr);

  print("\n -------------------\nHad slides too long: ");
  File longFile = new File("NewSongs/_long.txt");
  String longStr = "";
  for (var id in tooLong) {
    print(id);
    longStr += (id.toString() + "\n");
  }
  longFile.writeAsStringSync(longStr);
}

Song getSong(File songFile) {
  /*
  Strip away unused xml
  */
  String lyrics = songFile.readAsStringSync();
  lyrics = lyrics.substring(
      lyrics.indexOf("<lyrics>") + 8, lyrics.indexOf("</lyrics>"));

  int id = int.parse(basename(songFile.path).substring(1, 4));

  if (lyrics.contains("||")) //I already did it manually (probably better)
    return Song(id, null);
  else
    return Song(id, lyrics);
}

List<Verse> getVerses(Song song) {
  /*
  Split to lines list
  Split to verses:
    Split per regex
    Save id
    Cut away id
    Save lines
  */
  String lyrics = song.lyrics;

  List<Verse> verses = [];

  List<String> verseStrings = lyrics.split(new RegExp(r"(?=(\[.*\]))"));

  for (var verseString in verseStrings) {
    List<String> lines = verseString.split("\n");
    lines.removeWhere((line) => line.trim() == "");

    String id = lines[0];
    lines.removeAt(0);

    lines = formatLines(lines, song);

    verses.add(Verse(id, lines));
  }

  return verses;
}

List<String> formatLines(List<String> lines, Song song) {
  /*
  Get average line length
  If less than X, put every second line after the first
  */

  int sum = 0;
  int num = 0;
  for (var line in lines) {
    sum += line.length;
    num++;
  }
  double avgLen = sum / num;
  if (avgLen < 18) {
    for (var i = 0; i < lines.length - 2; i++) {
      lines[i] = lines[i].trimRight() + " " + (lines[i + 1]).trim();
      lines.removeAt(i + 1);
    }
  }

  /*
  Split the verse to slides 
    If more than 6 lines left of verse, split after 4
    If less than 6, split after 3
    If max 4, keep.
  */

  int linesLeft = lines.length;
  int index = 0;
  {
    while (linesLeft > 6) {
      //split every 4th
      linesLeft -= 4;
      index = lines.length - linesLeft;

      lines.insert(index, " ||");
    }
    if (linesLeft > 4 && linesLeft <= 6) {
      //split after 3
      linesLeft -= 3;
      index = lines.length - linesLeft;
      lines.insert(index, " ||");
    }
    if (avgLen > 38 && linesLeft == 4) {
      //If lines are long, split to two-line slides
      linesLeft -= 2;
      index = lines.length - linesLeft;
      lines.insert(index, " ||");
    }
    if (avgLen > 55 && linesLeft == 3) {
      linesLeft--;
      index = lines.length - linesLeft;
      lines.insert(index, " ||");
    }
    if (avgLen > 80 && linesLeft == 2) {
      //If lines are very long, split to one-line slides
      linesLeft--;
      index = lines.length - linesLeft;
      lines.insert(index, " ||");
    }
  }
  List<String> fixedLines = [];
  lines.forEach((element) {
    element = element.trim();
    element = " " + element;
    fixedLines.add(element);
  });

  lines = fixedLines;

  /*
  Count characters per slide and per line
  Print id where more than x, to deal with later
  */
  {
    String verseString = lines.join();

    List<String> slides = verseString.split("||");
    int longestSlide = 0;
    for (var slide in slides) {
      if (slide.length > longestSlide) longestSlide = slide.length;
    }
    if (longestSlide > 170) {
      print(song.id.toString() + " has a slide too long!");
      if (!tooLong.contains(song.id)) tooLong.add(song.id);
    }
  }
  return lines;
}

class Verse {
  String id;
  List<String> lines;

  Verse(this.id, this.lines);
}

class Song {
  int id;
  String lyrics;

  Song(this.id, this.lyrics);
}
