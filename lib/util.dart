import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:collection/collection.dart';
import 'package:yaml/yaml.dart';
import 'package:mp3_info/mp3_info.dart';

class PodcastItem {
  final String section;
  final String title;
  final String summary;
  final String description;
  final String link;
  final String txtLink;
  final String pubDate;
  final int length;
  final Duration duration;
  final String guid;

  PodcastItem._create(
      this.section,
      this.title,
      this.summary,
      this.description,
      this.link,
      this.txtLink,
      this.pubDate,
      this.length,
      this.duration,
      this.guid);

  static Future<PodcastItem> create(String filename, String asset) async {
    final regex = RegExp(r'#\s*([^\s]+)\s*([^\s]+)');
    final content = await File(filename)
        .openRead()
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .take(2)
        .toList();
    final match = regex.firstMatch(content[0]);
    final section = match.group(1);
    final title = match.group(2);
    final summary = content[1];
    final link = p.join(p.basename(asset), '${_getChapterName(filename)}.mp3');
    final src = p.basename(p.dirname(filename));
    final txtLink = p.join(p.basename(src), p.basename(filename));
    final mp3File = File(link);
    final mp3 = MP3Processor.fromFile(mp3File);
    final stats = await mp3File.stat();
    final pubDate = stats.modified.toIso8601String();
    final length = stats.size;
    final duration = mp3.duration;

    return PodcastItem._create(section, title, summary, summary, link, txtLink,
        pubDate, length, duration, link);
  }
}

/// extract titles from the src directory
FutureOr<List<PodcastItem>> extractTitles(String src, String asset) async {
  final titles = <PodcastItem>[];
  var lister = Directory(src).listSync()
    ..sort((a, b) => _pathCompare(a.path, b.path));
  for (final file in lister) {
    if (file.path.endsWith('.md')) {
      titles.add(await PodcastItem.create(file.path, asset));
    }
  }

  return titles;
}

FutureOr<String> genMarkdown(String src, String asset) async {
  final titles = await extractTitles(src, asset);
  final grouped = groupBy(titles, (PodcastItem item) => item.section);
  var result = <String>[];
  for (final entry in grouped.entries) {
    final list = entry.value.map(
        (item) => '- ${item.title}: [文字](${item.txtLink}) [朗读](/${item.link})');
    result.add('## ${entry.key}\n\n${list.join("\n")}');
  }

  return result.join('\n\n');
}

FutureOr<String> genPodcast(String src, String asset) async {
  final titles = await extractTitles(src, asset);
  final doc = await _getChannelInfo('channel.yml');
  final channel = await _genChannelInfo(doc);

  var items = <String>[];
  for (final title in titles) {
    items.add(await _genItem(doc, title));
  }

  return '''
  <?xml version="1.0" encoding="UTF-8"?>
    <rss xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd" version="2.0">
    <channel>
    $channel
    </channel>
    ${items.join('\n')}
  </rss>
  ''';
}

FutureOr<String> genHtml(String src, String asset) async {
  final titles = await extractTitles(src, asset);
  final doc = await _getChannelInfo('channel.yml');
  final grouped = groupBy(titles, (PodcastItem item) => item.section);
  var body = <String>[];
  for (final entry in grouped.entries) {
    final list = entry.value.map(
        (item) => '''
        <li>${item.title}: <audio controls><source src="${item.link}" type="audio/mpeg"></audio></li>
        ''');
    body.add('<h2>${entry.key}</h2><ul>${list.join("")}</ul>');
  }

  return '''
  <!DOCTYPE html>
  <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>${doc['title']}</title>
      <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/bulma/0.7.5/css/bulma.min.css" />
      <style>
        * {font-size: 20px;}
        h1, h2 {
          color: #363636;
          font-weight: 600;
          line-height: 2;
        }
        h1 { font-size: 2rem; text-align: center; }
        h2 { font-size: 1.6rem;}
        ul {
          display: flex;
          flex-direction: row;
          flex-wrap: wrap;
          text-decoration: none;
        }
        li { padding: 10px; display: grid; height: 120px; width: 33%;}
      </style>
    </head>
    <body>
    <div class="container">
    <h1>${doc['title']}</h1>
    ${body.join('<hr/>')}
    </div>
    </body>
  </html>
  ''';

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

// private functions

FutureOr<String> _genChannelInfo(dynamic doc) async {
  final imageUrl = p.join(doc['link'], doc['image']);
  final keywords = doc['keywords'].join(',');
  return '''
  <title>${doc['title']}</title>
  <link>${doc['link']}<link>
  <language>${doc['language']}</language>
  <itunes:subtitle>${doc['subtitle'] ?? ''}</itunes:subtitle>
  <itunes:author>${doc['author']}</itunes:author>
  <itunes:summary>${doc['description']}</itunes:summary>
  <description>${doc['description']}</description>
  <itunes:owner>
      <itunes:name>${doc['author']}</itunes:name>
  </itunes:owner>
  <itunes:explicit>no</itunes:explicit>
  <itunes:image href="${imageUrl}" />
  <itunes:category text="${doc['category']}"/></itunes:category>
  <itunes:keywords>${keywords}</itunes:keywords>
  ''';
}

FutureOr<String> _genItem(dynamic doc, PodcastItem item) {
  final link = p.join(doc['link'], item.link);
  final duration = _formatDuration(item.duration);
  return '''
  <item>
      <title>${item.title}</title>
      <itunes:summary>${item.summary}</itunes:summary>
      <description>${item.description}</description>
      <link>${link}</link>
      <enclosure url="${link}" type="audio/mpeg" length="${item.length}"></enclosure>
      <pubDate>${item.pubDate}</pubDate>
      <itunes:author>${doc['author']}</itunes:author>
      <itunes:duration>${duration}</itunes:duration>
      <itunes:explicit>no</itunes:explicit>
      <guid>${link}</guid>
  </item>
  ''';
}

/*
title: 史记
link: https://shiji-podcast.qiaopang.com/
description: >
  提供《史记》全文的讯飞 TTS 朗读
image: cover.jpg
copyright: Copyright 2020 Tyr Chen - For Personal Use Only
language: zh-CN
author: Tyr Chen
category: History
keywords: 史记, 中国历史
*/
dynamic _getChannelInfo(String filename) async {
  final file = File(filename);
  final exists = await file.exists();
  if (!exists) throw 'Channel config "${filename}" does not exist! Please create one.';
  final content = await file.readAsString();
  return loadYaml(content);
}

int _pathCompare(String a, String b) {
  final a1 = int.parse(_getChapterName(a));
  final b1 = int.parse(_getChapterName(b));
  return a1 - b1;
}

String _getChapterName(String filename) {
  return p.basenameWithoutExtension(filename);
}

String _formatDuration(Duration duration) {
  return [duration.inHours, duration.inMinutes, duration.inSeconds]
      .map((seg) => seg.remainder(60).toString().padLeft(2, '0'))
      .join(':');
}
