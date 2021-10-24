import 'dart:io';
import 'package:string_similarity/string_similarity.dart';
import 'dart:isolate';

/*
PSEUDO
Find groups of songs that are similar
Give each points on:
 - Van-e olyan diája ami több mint a max / oldal
 - Van-e benne tördelés
 - Van-e vetítési sorrend benne
 - Minden központozásra 1-1 pont
 - Minden nagybetűre 1-1 pont
 - Tartalmaz speciális versszaktípust (t, b, p)
 - Jó hosszúságú sorok
If close, ask user
Delete the losers
*/

List<SimilarGroup> similarGroups = List<SimilarGroup>();
List<Song> songs = List<Song>();
int finishedSearching = 0;
List<Song> songsToDelete = List<Song>();

void main() {
  print("OpenSong duplicated song cleaner\nBy: Benedek Fodor");
  //Get list of songs
  Directory songsDir = Directory("Songs");
  for (var element in songsDir.listSync(recursive: true, followLinks: true)) {
    if (element is File) {
      List<Score> scores = getScores(element);
      int totalScore = 0;
      for (var score in scores) {
        totalScore += score.score;
      }

      songs.add(Song(element, getLyrics(element), scores, totalScore));
    }
  }

  File scoresReportFile = new File("ScoresReport.txt");
  String scoresReport = "";

  for (Song song in songs) {
    scoresReport +=
        (song.file.toString() + " Total: " + song.totalScore.toString() + "\n");
    for (Score score in song.scores) {
      scoresReport +=
          ("- " + score.name + ": " + score.score.toString() + "\n");
    }
  }

  scoresReportFile.writeAsStringSync(scoresReport);

  for (Song song in songs /*.sublist(0, 20)*/) {
    List<SimilarElement> similars = List<SimilarElement>();

    for (Song songCompareTo in songs.where((element) =>
        (element != song) &&
        !(similarGroups.any((element) => element.similars.contains(song))))) {
      //print("i " + song.file.toString());
      double similarity = song.lyrics.similarityTo(songCompareTo.lyrics);
      if (similarity > 0.6) {
        similars.add(SimilarElement(songCompareTo, song, similarity));
      }
    }

    similarGroups.add(SimilarGroup(song, similars));
    print(song.file.toString() + "\tSimilars: " + similars.length.toString());
  }

  similarGroups.removeWhere((element) => element.similars.isEmpty);

  print(similarGroups.length);

  File similarGroupsOutputFile = new File("Similars.txt");
  String similarGroupsOutput = "";
  for (var group in similarGroups) {
    similarGroupsOutput += ("----\nMASTER: " +
        group.master.totalScore.toString() +
        " " +
        group.master.file.toString() +
        "\n");
    for (var similar in group.similars) {
      similarGroupsOutput += (" - " +
          ((similar.similarity * 100).round() / 100).toString() +
          " " +
          similar.song.totalScore.toString() +
          " " +
          similar.song.file.toString() +
          "\n");
    }
  }
  similarGroupsOutputFile.writeAsStringSync(similarGroupsOutput);

  /*
  For each similar group:
  Master becomes part of group
  Sort elements by score
  Remove first element
  Mark others from delete
  Remove groups which contain others
  */
  File deleteReportFile = new File("DeleteReport.txt");
  String deleteReport = "";

  for (var group in similarGroups.toList()) {
    List<Song> similars = List<Song>();
    for (var item in group.similars) {
      similars.add(item.song);
    }
    similars.add(group.master);

    similars.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    deleteReport += "---\n";
    deleteReport += ("keeping: " +
        similars[0].file.toString() +
        similars[0].totalScore.toString() +
        "\n");
    similars.removeAt(0);

    for (var item in similars) {
      deleteReport +=
          (item.file.toString() + " " + item.totalScore.toString() + "\n");
      songsToDelete.add(item);
      similarGroups.removeWhere((element) => element.master == item);
    }
  }
  deleteReportFile.writeAsString(deleteReport);

  songsToDelete.forEach((element) {
    print(element.file);
    if (element.file.existsSync()) {
      element.file.deleteSync();
    }
  });
}

List<Score> getScores(File songFile) {
  List<Score> scores = List<Score>();
  String lyrics = getLyrics(songFile);

  //Presentation order present (if yes, 60 pluspoints)
  scores
      .add(Score("presentation", (getPresentOrder(songFile) != "" ? 100 : 0)));

  //Special verse types (10 pluspoints if it does contain any)
  List<String> verseTokens = lyrics.split("[");
  for (int i = 0; i < verseTokens.length; i++) {
    try {
      verseTokens[i] = verseTokens[i].substring(0, 1);
    } catch (e) {
      print(e.toString());
    }
  }
  //I'm tired and won't come up with a more elegant solution...
  verseTokens.removeWhere((element) => element.contains("V"));
  verseTokens.removeWhere((element) => element.contains("v"));
  verseTokens.removeWhere((element) => element.contains("C"));
  verseTokens.removeWhere((element) => element.contains("c"));

  scores.add(Score("specialTokens", (verseTokens.length > 1 ? 10 : 0)));

  //Good length lines (Ideal: 30 char) (15 max points, can be negative)
  List<String> lines = lyrics.split("\r\n");
  lines.removeWhere((element) => element.contains("["));
  int sum = 0;
  for (var line in lines) {
    sum += line.length;
  }
  double avgLineLength = sum / lines.length;
  scores.add(Score("linesLength", (15 - (30 - avgLineLength.round()).abs())));

  //Max char limit per page (if more, -50 points)
  List<String> slides = lyrics.split(new RegExp(r"([\[|])"));
  int maxSlideLength = 0;
  for (var slide in slides) {
    if (slide.length > maxSlideLength) maxSlideLength = slide.length;
  }
  scores.add(Score("maxSlideLenth", (maxSlideLength > 180 ? -50 : 0)));

  //Path priorities: Református énekeskönyv 80, Refisz 20, Ifjúsági 25, Sófár 10
  int folderScore = 0;
  if (songFile.path.contains("Református énekeskönyv")) {
    folderScore = 80;
  } else if (songFile.path.contains("Refisz")) {
    folderScore = 20;
  } else if (songFile.path.contains("Ifjúsági")) {
    folderScore = 25;
  } else if (songFile.path.contains("Sófár")) {
    folderScore = 10;
  }
  scores.add(Score("folderScore", folderScore));

  scores.add(Score("length", (lyrics.length * 0.75).round()));

  return scores;
}

/* void findSimilars(Song song, List<Song> songs) {
  List<SimilarElement> similars = List<SimilarElement>();

  for (Song songCompareTo in songs.where((element) => element != song)) {
    print("i " + song.file.toString());
    double similarity = song.lyrics.similarityTo(songCompareTo.lyrics);
    if (similarity > 0.6) {
      similars.add(SimilarElement(songCompareTo, song, similarity));
    }
  }

  similarGroups.add(SimilarGroup(song, similars));
  print(song.file.toString() + "\tSimilars: " + similars.length.toString());

  finishedSearching++;
}
 */

String getLyrics(File songFile) {
  String lyrics = songFile.readAsStringSync();
  //try {
    return lyrics.substring(
        lyrics.indexOf("<lyrics>") + 8, lyrics.indexOf("</lyrics>"));
  /*} catch (e) {
    print(e.toString());
    songFile.delete();
    main();
  }*/
}

String getPresentOrder(File songFile) {
  String presentOrder = songFile.readAsStringSync();
  return presentOrder.substring(presentOrder.indexOf("<presentation>") + 14,
      presentOrder.indexOf("</presentation>"));
}

class SimilarElement {
  Song song;
  Song master;
  double similarity;

  SimilarElement(this.song, this.master, this.similarity);
}

class SimilarGroup {
  Song master;
  List<SimilarElement> similars;

  SimilarGroup(this.master, this.similars);
}

class Song {
  File file;
  String lyrics;
  List<Score> scores;
  int totalScore;

  Song(this.file, this.lyrics, this.scores, this.totalScore);
}

class Score {
  String name;
  int score;

  Score(this.name, this.score);
}
