import 'dart:io';

File kottaData = File("kotta_data.txt");
String baseURL = "https://enekeskonyv.reformatus.hu/";

void main(List<String> arguments) async {
  List<String> dataLines = kottaData.readAsLinesSync();
  List<Sheet> sheets = [];

  print("Parsing data file...");

  for (String line in dataLines.where((element) => element.startsWith("T"))) {
    sheets.add(Sheet(int.parse(line.substring(1, line.indexOf('.'))),
        "$baseURL${dataLines[dataLines.indexOf(line) + 1]}"));
  }

  sheets.sort((a, b) => a.songID.compareTo(b.songID));

  print("Downloading...");

  for (Sheet sheet in sheets) {
    print("Downloading ${sheet.songID}: ${sheet.link}");
    final request = await HttpClient().getUrl(Uri.parse(sheet.link));
    final response = await request.close();
    File("sheets\\S${sheet.songID}.jpg").createSync(recursive: true);
    await response.pipe(File("sheets\\S${sheet.songID}.jpg").openWrite());
    print("   Done.");
    await Future.delayed(Duration(seconds: 1));
  }
}

class Sheet {
  int songID;
  String link;

  Sheet(this.songID, this.link);
}
