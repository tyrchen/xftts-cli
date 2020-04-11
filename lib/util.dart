import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import "package:collection/collection.dart";

/// extract titles from the src directory
FutureOr<List<List<String>>> extractTitles(String src, String asset) async {
  final titles = <List<String>>[];
  final regex = RegExp(r'#\s*([^\s]+)\s*([^\s]+)');
  var lister = Directory(src)
    .listSync()
    ..sort((a, b) => _pathCompare(a.path, b.path));
  for(final file in lister) {
    if (file.path.endsWith('.md')) {
        final title = await File(file.path)
          .openRead()
          .transform(utf8.decoder)
          .transform(LineSplitter())
          .take(1).toList();
        final match = regex.firstMatch(title[0]);
        titles.add([match.group(1), match.group(2), p.join(p.basename(asset), '${_getChapterName(file.path)}.mp3')]);
      }
  }

  return titles;
}

FutureOr<String> genMarkdown(String src, String asset) async {
  final titles = await extractTitles(src, asset);
  final grouped = groupBy(titles, (item) => item[0]);
  var result = <String>[];
  for(final entry in grouped.entries) {
    final list = entry.value.map((item) => '- ${item[1]}: ![](${item[2]})');
    result.add('## ${entry.key}\n\n${list.join("\n")}');
  }
    
  return result.join('\n\n');
}

FutureOr<String> loadContent(String filename) async {
  final file = File(filename);
  final exists = await file.exists();
  if (!exists) return '';
  return await file.readAsString();
}

void writeFile(String filename, String content) async {
  final file = File(filename);
  await file.writeAsString(content);
}

int _pathCompare(String a, String b) {
  final a1 = int.parse(_getChapterName(a));
  final b1 = int.parse(_getChapterName(b));
  return a1 - b1;
}

String _getChapterName(String filename) {
  return p.basenameWithoutExtension(filename);
}