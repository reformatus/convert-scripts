import 'dart:io';
import 'package:image/image.dart';
import 'package:path/path.dart';

Directory sheetsDir = Directory("sheets");

const int darkCutoff = 4289506990;

List<int> notEnoughLinesErrorSongs = [];
List<int> tooManyLinesErrorSongs = [];
List<int> noLinesErrorSongs = [];
List<int> notEvenLinesErrorSongs = [];

void main(List<String> arguments) async {
  for (var sheetEntity in sheetsDir.listSync().sublist(0, 5)) {
    var sheetFile = sheetEntity as File;
    print(basenameWithoutExtension(sheetFile.path));

    int songID =
        int.parse(basenameWithoutExtension(sheetFile.path).substring(1));

    Image image = decodeJpg(sheetFile.readAsBytesSync());

    List<int> newSheetLineRows = getNewSheetLineRows(getContentRows(image));

    //image =
    //    markRows(image, getContentRows(image, reversed: true), [150, 150, 150]);

    //image = markRows(image, newSheetLineRows, [255, 0, 0]);

    int i = 1;

    for (Image part in getParts(image, newSheetLineRows)) {
      File partFile = File("parts_white\\P$songID-$i.jpg");
      partFile.createSync(recursive: true);
      partFile
          .writeAsBytesSync(encodeJpg(processImage(part, OutputType.white)));

      partFile = File("parts_transparent\\P$songID-$i.png");
      partFile.createSync(recursive: true);
      partFile.writeAsBytesSync(
          encodePng(processImage(part, OutputType.transparent)));

      partFile = File("parts_blue\\P$songID-$i.jpg");
      partFile.createSync(recursive: true);
      partFile.writeAsBytesSync(encodeJpg(processImage(part, OutputType.blue)));

      i++;
    }

/*
    for (Image part in getParts(image, newSheetLineRows)) {
      File partFile = File("parts_white\\P$songID-$i.jpg");
      partFile.createSync(recursive: true);
      partFile.writeAsBytesSync(encodeJpg(part));
      i++;
    }
*/
/*
    File markedPicture = File("marked\\M$songID.jpg");
    markedPicture.createSync(recursive: true);
    markedPicture.writeAsBytesSync(encodeJpg(image));
*/
    //errorCheck(songID, image.height, newSheetLineRows);
    //break;
  }

  saveReport();
}

enum OutputType { white, transparent, blue }

Image processImage(Image original, OutputType outputType) {
  if (outputType == OutputType.white) {
    return original;
  } else {
    List<int> originalBytes = original.getBytes();
    List<int> processedBytes = [];

    for (var i = 0; i < original.width * original.height * 4; i += 4) {
      int brightness =
          ((originalBytes[i] + originalBytes[i + 1] + originalBytes[i + 2]) / 3)
              .round()
              .clamp(0, 255);
      if (brightness > 200) brightness = 255;
      if (brightness < 20) brightness = 0;
      brightness = 255 - brightness; //invert

      if (outputType == OutputType.blue) {
        processedBytes.addAll([
          (37 + brightness).clamp(0, 255), //red
          (55 + brightness).clamp(0, 255), //green
          (69 + brightness).clamp(0, 255), //blue
          255
        ]);
      } else if (outputType == OutputType.transparent) {
        processedBytes.addAll([255, 255, 255, brightness]);
      }
    }
    return Image.fromBytes(original.width, original.height, processedBytes);
  }
}

List<Image> getParts(Image original, List<int> sheetLineRows) {
  List<Image> parts = [];
  List<List<int>> lineRanges = [];
  List<List<int>> partsLineRanges = [];

  //int prevBeginRow = 0;
  for (int beginRow in sheetLineRows) {
    //print("Adding range from $beginRow");
    int length = ((sheetLineRows.indexOf(beginRow) == sheetLineRows.length - 1)
            ? original.height
            : (sheetLineRows[(sheetLineRows.indexOf(beginRow) + 1)])) -
        beginRow;
    //print(length);
    //List<int> _tempLineRange = [];
    /*
    for (int row = beginRow - 8; row < length + beginRow - 4; row++) {
      _tempLineRange.add(row);
    }
*/
    lineRanges.add(List<int>.generate(length, (index) => beginRow + index - 4));
  }
/*
  ? Not needed in the end
  int prevRow = sheetLineRows.first;
  int sum = 0;
  for (var row in sheetLineRows) {
    sum += row - prevRow;
    prevRow = row;
  }

  double avgHeight = sum / sheetLineRows.length - 1;
*/
  List<int> _tempRowsInPart = [];

  addLines(int amount) {
    //print("  Adding lines...");
    for (var i = 0; i < amount; i++) {
      //print("  Added 1 line ${lineRanges.first.first}");
      _tempRowsInPart.addAll(lineRanges.first);
      lineRanges.removeAt(0);
    }
    partsLineRanges.add(_tempRowsInPart);
    _tempRowsInPart = [];
  }

  while (lineRanges.isNotEmpty) {
    switch (lineRanges.length) {
      case 4:
        //print("Splitting last 4 lines.");
        addLines(2);
        addLines(2);
        break;
      case 2:
        //print("Adding last two lines.");
        addLines(2);
        break;
      default:
        //print("Adding 3 lines.");
        addLines(3);
        break;
    }
  }

  for (List<int> lineRange in partsLineRanges) {
    try {
      parts.add(Image.fromBytes(
          original.width,
          lineRange.length,
          original.getBytes(format: Format.rgb).sublist(
              lineRange.first * original.width * 3,
              lineRange.last * original.width * 3 + original.width * 3),
          format: Format.rgb));
    } catch (e) {
      print("Error when adding part for song!\n$e");
      parts.add(original);
    }
  }

  return parts;
}

saveReport() {
  File reportFile = File("report.log");
  reportFile.createSync(recursive: true);
  List<String> reportLines = [];

  notEvenLinesErrorSongs.sort();
  noLinesErrorSongs.sort();
  notEnoughLinesErrorSongs.sort();
  tooManyLinesErrorSongs.sort();

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
  reportLines.add("\nToo many lines in:");
  tooManyLinesErrorSongs.forEach((element) {
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
    tooManyLinesErrorSongs.add(songID);
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
