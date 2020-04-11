import 'dart:io';

import 'package:xftts_cli/mp3.dart';
import 'package:args/command_runner.dart';
import 'package:xftts_cli/util.dart';

void main(List<String> arguments) async {
  var runner = CommandRunner('podgen', 'generate podcast/website related files')
    ..addCommand(Mp3Command())
    ..addCommand(FeedCommand())
    ..addCommand(ReadmeCommand())
    ..addCommand(HtmlCommand());

  await runner.run(arguments);
}

class Mp3Command extends Command {
  final String name = 'mp3';
  final String description = 'Generate mp3 file for the given markdown file.';

  void run() async {
    if (argResults.rest.length != 2) _usage(this);
    final input = argResults.rest[0];
    final output = argResults.rest[1];

    await generateMp3(input, output);
  }
}

class FeedCommand extends Command {
  final String name = 'feed';
  final String description = 'Generate podcast.xml feed for the repo.';

  FeedCommand() {
    argParser.addOption('asset',
        abbr: 'a', defaultsTo: 'assets', help: 'asset path containing mp3.');
    argParser.addOption('output',
        abbr: 'o', defaultsTo: 'podcast.xml', help: 'output filename');
  }

  void run() async {
    if (argResults.rest.length != 1) _usage(this);
    final srcPath = argResults.rest[0];
    final content = await genPodcast(srcPath, argResults['asset']);
    await writeFile(argResults['output'], content);
  }
}

class HtmlCommand extends Command {
  final String name = 'html';
  final String description = 'Generate index.html for repo.';

  HtmlCommand() {
    argParser.addOption('asset',
        abbr: 'a', defaultsTo: 'assets', help: 'asset path containing mp3.');
    argParser.addOption('output',
        abbr: 'o', defaultsTo: 'index.html', help: 'output filename');
  }

  void run() async {
    if (argResults.rest.length != 1) _usage(this);

    final srcPath = argResults.rest[0];
    final content = await genHtml(srcPath, argResults['asset']);

    await writeFile(argResults['output'], content);
  }
}

class ReadmeCommand extends Command {
  final String name = 'readme';
  final String description = 'Generate index.html for repo.';

  ReadmeCommand() {
    argParser.addOption('asset',
        abbr: 'a', defaultsTo: 'assets', help: 'asset path containing mp3.');
    argParser.addOption('prelogue',
        abbr: 'l', defaultsTo: 'prelogue.md', help: 'prelogue file to use');
    argParser.addOption('output',
        abbr: 'o', defaultsTo: 'README.md', help: 'output filename');
  }

  void run() async {
    if (argResults.rest.length != 1) _usage(this);

    final srcPath = argResults.rest[0];
    final content = await genMarkdown(srcPath, argResults['asset']);
    final prelogue = await loadContent(argResults['prelogue']);
    await writeFile(argResults['output'], '$prelogue\n\n$content');
  }
}

void _usage(Command cmd) {
  print(cmd.usage);
  exit(0);
}
