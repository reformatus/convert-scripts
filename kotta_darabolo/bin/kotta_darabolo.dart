import 'dart:io';
import 'package:image/image.dart';
import 'package:path/path.dart';

Directory sheetsDir = Directory("sheets");

const double minAspectRatio = 16 / 9; //~1.45
const int darkCutoff = 4289506990;

List<int> notEnoughLinesErrorSongs = [];
List<int> tooManyLinesErrorSongs = [];
List<int> noLinesErrorSongs = [];
List<int> notEvenLinesErrorSongs = [];

List<int> lastPageOneLineSongs = [];
List<int> hasOneLinePageSongs = [];

void main(List<String> arguments) async {
  for (var sheetEntity in sheetsDir.listSync().sublist(0, 5)) {
    var sheetFile = sheetEntity as File;
    print(basenameWithoutExtension(sheetFile.path));

    int songID =
        int.parse(basenameWithoutExtension(sheetFile.path).substring(1));

    Image image = trimSheet(decodeJpg(sheetFile.readAsBytesSync()));

    List<SheetLine> newSheetLineRows = getSheetLines(getContentRows(image));

    //image =
    //    markRows(image, getContentRows(image, reversed: true), [150, 150, 150]);

    //image = markRows(image, newSheetLineRows, [255, 0, 0]);

    int i = 1;

    for (Image part in getParts(image, newSheetLineRows, songID)) {
      File partFile = File("parts_white\\P$songID-$i.jpg");
      partFile.createSync(recursive: true);
      partFile.writeAsBytesSync(
          encodeJpg(processSheet(part, OutputType.white), quality: 90));

      partFile = File("parts_transparent\\P$songID-$i.png");
      partFile.createSync(recursive: true);
      partFile.writeAsBytesSync(
          encodePng(processSheet(part, OutputType.transparent)));

      partFile = File("parts_blue\\P$songID-$i.jpg");
      partFile.createSync(recursive: true);
      partFile.writeAsBytesSync(
          encodeJpg(processSheet(part, OutputType.blue), quality: 90));

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

Image trimSheet(Image original) {
  var contentRows = getContentRows(original, fullWidth: true);
  int startRow = contentRows.first - 3;
  if (startRow < 0) startRow = 0;
  int endRow = contentRows.last + 5;
  if (endRow >= original.height) endRow = original.height - 1;

  return Image.fromBytes(
      original.width,
      endRow - startRow,
      original
          .getBytes(format: Format.rgb)
          .sublist(startRow * original.width * 3, endRow * original.width * 3),
      format: Format.rgb);
}

enum OutputType { white, transparent, blue }

Image processSheet(Image original, OutputType outputType) {
  if (outputType == OutputType.white) {
    return original;
  }

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

List<Image> getParts(Image original, List<SheetLine> lines, int songID) {
  List<Image> parts = [];
  List<SheetPage> pages = [];
  int _numberOfLines = 0;
  int _begin = lines.first.beginRow;
  int _end;

  generatePageOf(int num) {
    pages.add(SheetPage(
        lines.first.beginRow, lines[num - 1].endRow, original.width, num));
    lines.removeRange(0, num);
  }

  bool isAspectRatioOfNextLinesOk(int num) {
    return (original.width / (lines[num - 1].endRow - lines[0].beginRow) >
        minAspectRatio);
  }

  while (lines.isNotEmpty) {
    //! Adds 3 lines, except when 4 lines left (adds 2)
    //! Adds rest of the lines when less than 3 left

    switch (lines.length) {
      case 4:
        if (isAspectRatioOfNextLinesOk(2)) {
          generatePageOf(2);
        }
        break;
      case 2:
        if (isAspectRatioOfNextLinesOk(2)) {
          generatePageOf(2);
        } else {
          generatePageOf(1);
          hasOneLinePageSongs.add(songID);
        }
        break;
      case 1:
        generatePageOf(1);
        hasOneLinePageSongs.add(songID);
        lastPageOneLineSongs.add(songID);
        break;

      //! lines.length is 3; or >=5
      default:
        if (isAspectRatioOfNextLinesOk(3)) {
          generatePageOf(3);
        } else if (isAspectRatioOfNextLinesOk(2)) {
          generatePageOf(2);
        } else {
          generatePageOf(1);
          hasOneLinePageSongs.add(songID);
        }
    }
  }

  for (SheetPage page in pages) {
    try {
      parts.add(Image.fromBytes(
          original.width,
          page.rowCount,
          original.getBytes(format: Format.rgb).sublist(
              page.beginRow * original.width * 3,
              page.endRow * original.width * 3),
          format: Format.rgb));
    } catch (e) {
      print(
          "Error when adding part for song! Adding full song and returning.\n$e");
      parts.add(original);
      return parts;
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

List<SheetLine> getSheetLines(List<int> contentRows) {
  /*
  0-100px nem kell figyelni
  Sorok: 85-100 képpont

  Végig sorokon: Egybefüggő területek rögzítése
  Végig területeken: Ami több, mint 85 képpont, sor rögzítése (első elemnél eggyel alacsonyabb szám)
  */

  List<SheetLine> sheetLines = [];

  int _begin = contentRows.first;

  int prev = contentRows.first - 1;

  for (int row in contentRows) {
    if (row - 1 != prev) {
      sheetLines.add(SheetLine(_begin, prev));
      _begin = row;
    }
    prev = row;
  }

  /*
  for (int row in contentRows) {
    _tempFirstRow ??= row;
    _tempLastRow = row;

    if ((row - 1) > prevRow ||
        contentRows.indexOf(row) == contentRows.length - 1) {
      if (_tempLastRow - _tempFirstRow > 3)
        sheetLines.add(SheetLine(_tempFirstRow, _tempLastRow - 1));
      _tempFirstRow = null;
    }

    prevRow = row;
  }
*/
  sheetLines
      .removeWhere((element) => element.length < 75 || element.length > 125);

  /*print("GROUPS\n\n");

  rowGroups.forEach((element) {
    print(
        "length: ${element.length}, first: ${element.first}, last: ${element.last}");
  });*/

  return sheetLines;
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

List<int> getContentRows(Image image,
    {bool reversed = false, bool fullWidth = false}) {
  List<int> contentRows = [];
  bool emptyRow = true;
  for (var y = 0; y < image.height; y++) {
    emptyRow = true;
    for (var x = 0; x < (fullWidth ? image.width : 34); x++) {
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

class SheetLine {
  int beginRow;
  int endRow;
  int get length => endRow - beginRow;

  SheetLine(this.beginRow, this.endRow);
}

class SheetPage {
  int beginRow;
  int endRow;
  int? numberOfLines;
  int width;
  double get aspectRatio => width / (endRow - beginRow);
  int get rowCount => endRow - beginRow;

  SheetPage(this.beginRow, this.endRow, this.width, this.numberOfLines);
}
