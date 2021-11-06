import 'dart:io';
import 'package:image/image.dart';
import 'package:path/path.dart';

Directory sheetsDir = Directory("sheets");

const int darkCutoff = 4289506990;

List<int> notEnoughLinesErrorSongs = [];
List<int> tooMuchLinesErrorSongs = [];
List<int> noLinesErrorSongs = [];
List<int> notEvenLinesErrorSongs = [];

void main(List<String> arguments) async {
  for (var sheetEntity in sheetsDir.listSync().sublist(0)) {
    var sheetFile = sheetEntity as File;
    print(basenameWithoutExtension(sheetFile.path));

    int songID =
        int.parse(basenameWithoutExtension(sheetFile.path).substring(1));

    Image image = decodeJpg(sheetFile.readAsBytesSync());

    List<int> newSheetLineRows = getNewSheetLineRows(getContentRows(image));

    //image =
    //    markRows(image, getContentRows(image, reversed: true), [150, 150, 150]);

    image = markRows(image, newSheetLineRows, [255, 0, 0]);

    File markedPicture = File("marked\\M$songID.jpg");
    markedPicture.createSync(recursive: true);
    markedPicture.writeAsBytesSync(encodeJpg(image));

    //errorCheck(songID, image.height, newSheetLineRows);
    //break;
  }

  File reportFile = File("report.log");
  reportFile.createSync(recursive: true);
  List<String> reportLines = [];

  notEvenLinesErrorSongs.sort();
  noLinesErrorSongs.sort();
  notEnoughLinesErrorSongs.sort();
  tooMuchLinesErrorSongs.sort();

  reportLines.add("Not enough lines in:");
  notEnoughLinesErrorSongs.forEach((element) {
    reportLines.add(element.toString() +
        (notEvenLinesErrorSongs.contains(element) ? "+" : ""));
  });
  reportLines.add("\nNot even, but enough lines in:");
  notEvenLinesErrorSongs
      .where((element) => !notEnoughLinesErrorSongs.contains(element))
      .forEach((element) {
    reportLines.add(element.toString());
  });
  reportLines.add("\nNo lines in:");
  noLinesErrorSongs.forEach((element) {
    reportLines.add(element.toString());
  });
  reportLines.add("\nToo much lines in:");
  tooMuchLinesErrorSongs.forEach((element) {
    reportLines.add(element.toString());
  });

  reportFile.writeAsStringSync(reportLines.join("\n"));

  print("Report saved.");
}



errorCheck(int songID, int sheetHeight, List<int> sheetLineRows) {
  if (sheetLineRows.isEmpty) {
    noLinesErrorSongs.add(songID);
    print("No lines!");
    return;
  }

  int expectedLines = (sheetHeight / 170).round();
  int difference = sheetLineRows.length - expectedLines;

  if (difference > 2) {
    tooMuchLinesErrorSongs.add(songID);
    print("Too much lines!");
  } else if (difference < -2) {
    notEnoughLinesErrorSongs.add(songID);
    print("Not Enough lines!");
  }

  int prevRow = sheetLineRows.first;
  int sum = 0;
  for (var row in sheetLineRows) {
    sum += row - prevRow;
    prevRow = row;
  }
  double avgHeight = sum / sheetLineRows.length - 1;

  //print("avgHeight = " + avgHeight.toString());

  prevRow = sheetLineRows.first;
  bool unevenLines = false;
  for (var row in sheetLineRows.sublist(1)) {
    //print("row $row, evenity ${(row - prevRow) / avgHeight}");
    if ((row - prevRow) / avgHeight > 1.8) {
      unevenLines = true;
    }
    prevRow = row;
  }
  if (unevenLines) notEvenLinesErrorSongs.add(songID);
}

List<int> getNewSheetLineRows(List<int> contentRows) {
  /*
  0-100px nem kell figyelni
  Sorok: 85-100 képpont

  Végig sorokon: Egybefüggő területek rögzítése
  Végig területeken: Ami több, mint 85 képpont, sor rögzítése (első elemnél eggyel alacsonyabb szám)
  */

  List<int> newSheetLineRows = [];

  List<List<int>> rowGroups = [];

  List<int> _tempRowGroup = [];
  int prevRow = -1;
  for (int row in contentRows) {
    if ((row - 1) > prevRow ||
        contentRows.indexOf(row) == contentRows.length - 1) {
      if (_tempRowGroup.length > 3) rowGroups.add(_tempRowGroup);
      _tempRowGroup = [];
    }

    _tempRowGroup.add(row);

    prevRow = row;
  }

  rowGroups
      .where((element) => element.length > 75 && element.length < 125)
      .forEach((element) {
    newSheetLineRows.add(element.first);
  });

  /*print("GROUPS\n\n");

  rowGroups.forEach((element) {
    print(
        "length: ${element.length}, first: ${element.first}, last: ${element.last}");
  });*/

  return newSheetLineRows;
}

Image markRows(Image original, List<int> rows, List<int> replaceWithRGB) {
  assert(replaceWithRGB.length == 3);

  List<int> newPixels = [];

  for (var y = 0; y < original.height; y++) {
    for (var x = 0; x < original.width; x++) {
      newPixels.addAll(rows.contains(y)
          ? replaceWithRGB
          : [
              (original.getPixel(x, y) & 0x000000FF),
              (original.getPixel(x, y) & 0x0000FF00) >> 8,
              (original.getPixel(x, y) & 0x00FF0000) >> 16
            ]);
    }
  }

  Image newImage = Image.fromBytes(original.width, original.height, newPixels,
      format: Format.rgb, channels: Channels.rgb);

  //print(
//      "length: ${newPixels.length}, length pixels: ${newImage.getBytes().length}, pixel 3 old: ${original.getBytes()[3]}, pixel 3 new: ${newPixels[3]}, pixel 3 image: ${newImage.getBytes()[3]}");

  return newImage;
}

List<int> getContentRows(Image image, {bool reversed = false}) {
  List<int> contentRows = [];
  bool emptyRow = true;
  for (var y = 0; y < image.height; y++) {
    emptyRow = true;
    for (var x = 0; x < 34; x++) {
      if (image.getPixel(x, y) < darkCutoff) emptyRow = false;
    }
    if (!(emptyRow ^ reversed)) contentRows.add(y);
  }

  //contentRows.forEach(print);

  return contentRows;
}

class Sheet {
  int songID;
  File sheetFile;
  Image image;

  Sheet(this.sheetFile, this.songID, this.image);
}
