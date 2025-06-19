class SongEntry {
  final String song;
  final Duration offset;
  SongEntry(this.song, this.offset);
}

class Template {
  final String name;
  final List<SongEntry> entries;
  Template(this.name, this.entries);
}
