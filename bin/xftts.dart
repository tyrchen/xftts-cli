import 'dart:io';
import 'package:args/args.dart';
import 'package:xftts_cli/gen.dart';

void main(List<String> arguments) async {
  var parser = ArgParser();
  parser.addFlag('help', abbr: 'h', callback: (help) {
    if (help) _usage();
  });
  
  final result = parser.parse(arguments);

  if (result.rest.length != 2) _usage();

  final input = result.rest[0];
  final output = result.rest[1];

  await generateMp3(input, output);
  print('$output was generated successfully!');
}

void _usage() {
  print('Usage: xftts <input_file> <output_file>');
  exit(0);
}