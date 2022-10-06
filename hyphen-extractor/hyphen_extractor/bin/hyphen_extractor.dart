import 'dart:io';
import 'dart:convert' show json;

File dataFile = File("data.json");
Map<String, String> hyphenData = {};
File outputFile = File("out.json");

void main(List<String> arguments) {
  Map dataJson = json.decode(dataFile.readAsStringSync());

  String allContent = (dataJson["songs"] as List).reduce((value, element) {
    (value as Map).putIfAbsent("allVerses", () => []);
    (value["allVerses"] as List).addAll(element["verses"]);
    return value;
  })["allVerses"].join("\n");

  //allContent = allContent.toLowerCase();
  allContent = allContent.replaceAll(RegExp(r"[\d.,!:;?\n]"), "");
  allContent = allContent.replaceAll('_', ' ');

  List<String> allParts = allContent.split(' ');
  List<String> currentParts = [];
  String currentWord = "";
  for (var i = 0; i < allParts.length; i++) {
    var part = allParts[i];

    currentParts.add(part);
    currentWord += part.replaceAll('-', "");

    if (!part.endsWith('-')) {
      if (currentParts.length > 1) {
        hyphenData.putIfAbsent(currentWord, () => currentParts.join(' '));
      }
      currentParts.clear();
      currentWord = "";
    }
  }
  print('done');

  outputFile.createSync();
  outputFile.writeAsStringSync(json.encode(hyphenData));
}
