import 'dart:io';
import 'package:front_matter/front_matter.dart' as fm;

import 'package:xftts/xftts.dart';

void generateMp3(String input, String output) async {
  final env = Platform.environment;
  final app = env["APP"] ?? '1';
  final appId = env['XF_TTS_ID$app'];
  final apiKey = env['XF_TTS_KEY$app'];
  final apiSecret = env['XF_TTS_SECRET$app'];
  final vcn = env['XF_TTS_VCN'] ?? 'xiaoyan';
  final speed = env['XF_TTS_SPEED'] ?? '70';
  final volume = env['XF_TTS_VOLUME'] ?? '60';

  final doc = await fm.parseFile(input);

  final tts =
      TTS(appId, apiKey, apiSecret, vcn: vcn, speed: int.parse(speed), volume: int.parse(volume));

  await tts.generateMp3ForMarkdown(doc.content ?? doc.toString(), output);
}
