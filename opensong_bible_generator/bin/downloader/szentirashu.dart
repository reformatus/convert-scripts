import 'dart:convert';

import '../globals.dart';

import 'package:http/http.dart' as http;

const baseUrl = "https://szentiras.hu/api";

// Unfinished implementation - Turns out they have 1904 Károli
// May finish later for 'bible' lib...
Future<List<Book>> getEmptyBooksFor(String translation) async {
  var response = await http.get(Uri.parse("$baseUrl/books/$translation"));
  var jsonResponse = jsonDecode(response.body);

  List<Book> books = [];

  for (var bookMap in jsonResponse["books"]) {
    books.add(Book(bookMap["name"], shortName: bookMap["abbrev"]));
  }

  return books;
}

Future<List<Verse>> getAllVerses(
    String book, int chapter, String translation) async {
  var response = await http
      .get(Uri.parse("$baseUrl/idezet/$book$chapter,1-9999/$translation"));
  var jsonResponse = jsonDecode(response.body);

  List<Verse> verses = [];
  int i = 1;
  for (var verseMap in jsonResponse["valasz"]["versek"]) {
    verses.add(Verse(i.toString(), verseMap["szoveg"]));
    i++;
  }

  return verses;
}
