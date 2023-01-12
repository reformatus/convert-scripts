import 'dart:convert';
import 'package:html/parser.dart' as html;

import '../globals.dart';

import 'package:http/http.dart' as http;

const baseUrl = "https://www.online-biblia.ro";

Throttler throttler = Throttler();
/*
main() async {
  await getBooksFor(4);
}
*/
Future<List<Book>> getBooksFor(int translationId) async {
  var bibleDoc = html.parse((await http.get(
    Uri.parse("$baseUrl/bible/$translationId"),
  ))
      .body);

  List<Book> books = [];
  for (var bookElement in bibleDoc.querySelectorAll(".book a")) {
    print("Scraping: ${bookElement.text}");

    await throttler.throttle();
    var bookDoc = html.parse(
        (await http.get(Uri.parse(baseUrl + bookElement.attributes["href"]!)))
            .body);

    List<Chapter> chapters = [];
    for (var chapterElement
        in bookDoc.querySelectorAll(".bible-chapter-list a")) {
      print("  ${chapterElement.text}");

      await throttler.throttle();
      var chapterDoc = html.parse((await http
              .get(Uri.parse(baseUrl + chapterElement.attributes["href"]!)))
          .body);

      List<Verse> verses = chapterDoc
          .querySelectorAll("a.vers")
          .asMap()
          .entries
          .map((e) => Verse(e.key + 1, e.value.text))
          .toList();

      chapters.add(Chapter(int.parse(chapterElement.text), verses));
    }

    books.add(Book(bookElement.text, chapters: chapters));

    if (books.length == 2) break; // TODO removeme
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
