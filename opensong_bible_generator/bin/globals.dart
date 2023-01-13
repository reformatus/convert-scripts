class Verse {
  String text;
  String num;

  Verse(this.num, this.text);
}

class Chapter {
  int num;
  List<Verse> verses;

  Chapter(this.num, this.verses);
}

class Book {
  String name;
  String? shortName;
  List<Chapter>? chapters;

  Book(
    this.name, {
    this.shortName,
    this.chapters,
  });
}
