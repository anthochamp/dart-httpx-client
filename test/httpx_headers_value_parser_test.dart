import 'package:test/test.dart';

import 'package:ac_httpx_client/src/headers/httpx_headers_value_parser.dart';

void main() {
  group('parseHttpComment', () {
    test('simple', () {
      expect(HttpxHeaderValueParser.parseHttpComment('(a)'), equals('a'));
    });
    test('recursive1', () {
      expect(HttpxHeaderValueParser.parseHttpComment('((a))'), equals('(a)'));
    });
    test('recursive2', () {
      expect(
        HttpxHeaderValueParser.parseHttpComment('(((a)))'),
        equals('((a))'),
      );
    });
  });

  group('parseHttpList', () {
    test('', () {
      expect(
        HttpxHeaderValueParser.parseHttpList('a,    \t"b, c"\t, f'),
        equals([
          'a',
          '"b, c"',
          'f',
        ]),
      );
    });

    test('', () {
      expect(
        HttpxHeaderValueParser.parseHttpList('a , b,\tc,d,  e, ,  ,f,'),
        equals([
          'a',
          'b',
          'c',
          'd',
          'e',
          'f',
        ]),
      );
    });

    test('', () {
      expect(
        HttpxHeaderValueParser.parseHttpList('a , "b,\tc,d,  e, ,  ",f,'),
        equals([
          'a',
          '"b,\tc,d,  e, ,  "',
          'f',
        ]),
      );
    });

    test('date1', () {
      expect(
        HttpxHeaderValueParser.parseHttpList('Sun, 06 Nov 1994 08:49:37 GMT'),
        equals([
          'Sun, 06 Nov 1994 08:49:37 GMT',
        ]),
      );
    });
    test('date2', () {
      expect(
        HttpxHeaderValueParser.parseHttpList('Sunday, 06-Nov-94 08:49:37 GMT'),
        equals([
          'Sunday, 06-Nov-94 08:49:37 GMT',
        ]),
      );
    });
    test('date3', () {
      expect(
        HttpxHeaderValueParser.parseHttpList('Sun Nov  6 08:49:37 1994'),
        equals([
          'Sun Nov  6 08:49:37 1994',
        ]),
      );
    });
    test('mixed', () {
      expect(
        HttpxHeaderValueParser.parseHttpList(
          'Sun Nov  6 08:49:37 1994, Sunday, 06-Nov-94 08:49:37 GMT, Sun, 06 Nov 1994 08:49:37 GMT, "hello, friend!", token',
        ),
        equals([
          'Sun Nov  6 08:49:37 1994',
          'Sunday, 06-Nov-94 08:49:37 GMT',
          'Sun, 06 Nov 1994 08:49:37 GMT',
          '"hello, friend!"',
          'token',
        ]),
      );
    });
  });
}
