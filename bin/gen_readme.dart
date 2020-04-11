import 'dart:io';
import 'package:args/args.dart';
import 'package:xftts_cli/util.dart';

void main(List<String> arguments) async {
  var parser = ArgParser();
  parser.addFlag('help', abbr: 'h', callback: (help) {
    if (help) _usage();
  });
  parser.addOption('asset', abbr: 'a', defaultsTo: 'assets');
  parser.addOption('prelogue', abbr: 'l', defaultsTo: 'prelogue.md');

  final result = parser.parse(arguments);

  if (result.rest.length != 2) _usage();

  final srcPath = result.rest[0];
  final outPath = result.rest[1];
  final content = await genMarkdown(srcPath, result['asset']);
  final prelogue = await loadContent(result['prelogue']);
  await writeFile(outPath, '$prelogue\n\n$content');
}

void _usage() {
  print('Usage: gen_readme <src_path> <output_file>');
  exit(0);
}
