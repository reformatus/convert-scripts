import 'dart:convert';
import 'package:html/dom.dart';
import 'package:html/parser.dart';

import '../globals.dart';

import 'package:http/http.dart' as http;

const baseUrl = "https://www.biblegateway.com/";

Throttler throttler = Throttler();

Future<List<Book>> getBooksFor(String translation) async {
  var bibleDoc = parse((await http.get(
    Uri.parse("$baseUrl/versions/$translation/#booklist"),
  ))
      .body);

  List<Book> books = [];
  for (var bookElement in [
    ...bibleDoc.querySelectorAll(".ot-book"),
    ...bibleDoc.querySelectorAll(".nt-book")
  ]) {
    String bookName = bookElement
        .querySelector('.book-name')!
        .nodes
        .whereType<Text>()
        .first
        .text
        .trim();
    print("Scraping: $bookName");

    List<Chapter> chapters = [];
    for (var chapterElement
        in bookElement.querySelectorAll(".chapters a")) {
      print("  ${chapterElement.text}");

      await throttler.throttle();
      var chapterDoc = parse((await http
              .get(Uri.parse(baseUrl + chapterElement.attributes["href"]!)))
          .body);

      var verseElements = chapterDoc.querySelectorAll("p .text");
      List<Element> elementsOfVerse = [];

      List<Verse> verses = [];
      for (int i = 0; i < verseElements.length; i++) {
        var verse = verseElements[i];
        elementsOfVerse.add(verse);

        if (i + 1 >= verseElements.length ||
            RegExp(r'^\d+\u00A0').hasMatch(verseElements[i + 1].text)) {
          verses.add(Verse(
              verses.length + 1,
              elementsOfVerse
                  .map((e) =>
                      e.nodes.whereType<Text>().map((e) => e.text).join())
                  .join(' ')));
          elementsOfVerse.clear();
        }
      }

      chapters.add(Chapter(int.parse(chapterElement.text), verses));
    }
    books.add(Book(bookName, chapters: chapters));
  }

  return books;
}

class Throttler {
  static int i = 0;
  Future throttle() async {
    i++;
    if (i % 10 == 0) {
      print("  Throttling...");
      await Future.delayed(Duration(seconds: 2));
      return;
    } else {
      return;
    }
  }
}
