// Copyright 2023, Anthony Champagne. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file:  member-ordering

import 'package:ac_dart_essentials/ac_dart_essentials.dart';

import 'httpx_headers_typedefs.dart';

class HttpxHeaderValueParser {
  // https://httpwg.org/specs/rfc9110.html#rfc.section.2.1
  static const httpVcharPattern = r'[\x21-\x7E]';

  // https://httpwg.org/specs/rfc9110.html#rfc.section.5.1
  static const httpFieldNamePattern = httpTokenPattern;

  // https://httpwg.org/specs/rfc9110.html#rfc.section.5.5
  static const httpObsTextPattern = r'[\x80-\xFF]';
  static const httpFieldVcharPattern =
      '(?:$httpVcharPattern|$httpObsTextPattern)';
  static const httpFieldContentPattern =
      '(?:$httpFieldVcharPattern|(?:[ \t]|$httpFieldVcharPattern)$httpFieldVcharPattern)';
  static const httpFieldValuePattern = '$httpFieldContentPattern+';

  // https://httpwg.org/specs/rfc9110.html#rfc.section.5.6.2
  static const httpTcharPattern = r'[!#$%&' '*+-.^_`|~0-9a-zA-Z]';
  static const httpTokenPattern = '$httpTcharPattern+';
  static const httpDelimitersPattern = r'[(),/:;<=>?@\[\]{}]\\"]';

  // https://httpwg.org/specs/rfc9110.html#rfc.section.5.6.3
  static const httpOWsPattern = r'[ \t]*';
  static const httpRWsPattern = r'[ \t]+';

  // https://httpwg.org/specs/rfc9110.html#rfc.section.5.6.4
  static const httpQdtextPattern =
      '(?:[ \\t\\x21\\x23-\\x5B\\x5D-\\x7E]|$httpObsTextPattern)';
  static String composeHttpQuotedPairPattern({
    String? outName,
    String? inName,
  }) =>
      '(?:[ \\t]|$httpVcharPattern|$httpObsTextPattern)'.inoutCapture(
        prePattern: r'\\',
        inCaptureName: inName,
        outCaptureName: outName,
      );
  static String composeHttpQuotedStringPattern({
    String? outName,
    String? inName,
  }) =>
      '(?:$httpQdtextPattern|${composeHttpQuotedPairPattern()})*'.inoutCapture(
        prePattern: r'"',
        postPattern: r'"',
        inCaptureName: inName,
        outCaptureName: outName,
      );

  // https://httpwg.org/specs/rfc9110.html#rfc.section.5.6.5
  static const httpCtextPattern =
      '(?:[ \\t\\x21-\\x27\\x2A-\\x5B\\x5D-\\x7E]|$httpObsTextPattern)';

  // https://httpwg.org/specs/rfc9110.html#rfc.section.5.6.7
  static const httpDayNamePattern = '(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun)';
  static const httpDayPattern = r'[\d]{2}';
  static const httpMonthPattern =
      '(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)';
  static const httpYearPattern = r'[\d]{4}';
  static const httpDate1Pattern =
      '(?:$httpDayPattern $httpMonthPattern $httpYearPattern)';
  static const httpTimeOfDayPattern = r'(?:[\d]{2}:[\d]{2}:[\d]{2})';
  static const httpImfFixdatePattern =
      '(?:$httpDayNamePattern, $httpDate1Pattern $httpTimeOfDayPattern GMT)';
  static const httpDate2Pattern =
      '(?:$httpDayPattern-$httpMonthPattern-[\\d]{2})';
  static const httpDayNameLPattern =
      '(?:Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)';
  static const httpRfc850DatePattern =
      '(?:$httpDayNameLPattern, $httpDate2Pattern $httpTimeOfDayPattern GMT)';
  static const httpDate3Pattern = '(?:$httpMonthPattern (?:[\\d]{2}| \\d))';
  static const httpAsctimeDatePattern =
      '(?:$httpDayNamePattern $httpDate3Pattern $httpTimeOfDayPattern $httpYearPattern)';
  static const httpObsDatePattern =
      '(?:$httpRfc850DatePattern|$httpAsctimeDatePattern)';
  static const httpDatePattern =
      '(?:$httpImfFixdatePattern|$httpObsDatePattern)';

  static String composeHttpPossibleCommentPattern({
    String? outName,
    String? inName,
  }) =>
      '(?:$httpCtextPattern|${composeHttpQuotedPairPattern()}|\\(.*\\))*'
          .inoutCapture(
        prePattern: r'\(',
        postPattern: r'\)',
        inCaptureName: inName,
        outCaptureName: outName,
      );

  static String composeHttpCommentPattern({
    String? outName,
    String? inName,
    String? possibleSubCommentOutName,
  }) =>
      '(?:$httpCtextPattern|${composeHttpQuotedPairPattern()}|${composeHttpPossibleCommentPattern(outName: possibleSubCommentOutName)})*'
          .inoutCapture(
        prePattern: r'\(',
        postPattern: r'\)',
        inCaptureName: inName,
        outCaptureName: outName,
      );

  static List<String> splitByWs(HttpxHeaderValue value) =>
      value.split(RegExp(httpOWsPattern));

  static String? parseHttpComment(String value) {
    // can't use a simple regex to decode comment because it's a recursive pattern
    final match = RegExp(composeHttpCommentPattern(
      inName: 'comment',
      possibleSubCommentOutName: 'possibleSubComment',
    )).firstMatch(value);

    if (match == null) {
      return null;
    }

    final possibleSubComment = match.namedGroup('possibleSubComment');

    if (possibleSubComment != null) {
      final subComment = parseHttpComment(possibleSubComment);

      if (subComment != null) {
        return '($subComment)';
      }
    }

    return match.namedGroup('comment');
  }

  static String? parseQuotedString(String value) {
    final match = RegExp(composeHttpQuotedStringPattern(inName: 'quotedString'))
        .firstMatch(value);

    if (match == null) {
      return null;
    }

    return match.namedGroup('quotedString');
  }

  static String quotedString(String value) => '"$value"';

  // https://httpwg.org/specs/rfc9110.html#rfc.section.5.6.1
  static Iterable<String> parseHttpList(String? value) {
    if (value == null) {
      return [];
    }

    final separators = RegExp(
      '$httpDatePattern,|${composeHttpQuotedStringPattern()}$httpOWsPattern,|,',
    ).allMatches('$value,');

    var values = <String>[];

    for (int index = 0; index < separators.length; index++) {
      final separator = separators.elementAt(index);

      // ignore: avoid-substring
      values.add(value.substring(
        index == 0 ? 0 : separators.elementAt(index - 1).end,
        separator.end - 1,
      ));
    }

    return values
        .map((e) => e.patternTrim(HttpxHeaderValueParser.httpOWsPattern))
        .toList()
      ..removeWhere((element) => element.isEmpty);
  }

  // https://httpwg.org/specs/rfc9110.html#rfc.section.5.3
  static String httpList(
    Iterable<String> values, {
    String spacing = ' ',
  }) {
    assert(HttpxHeaderValueParser.httpOWsPattern.entireMatch(spacing));

    return values.join(',$spacing');
  }
}
