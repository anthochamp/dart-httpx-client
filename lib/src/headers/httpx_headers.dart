// SPDX-FileCopyrightText: © 2023 - 2024 Anthony Champagne <dev@anthonychampagne.fr>
//
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';

import 'package:ac_dart_essentials/ac_dart_essentials.dart';
import 'package:collection/collection.dart';
import 'package:http_parser/http_parser.dart';

import 'httpx_headers_typedefs.dart';
import 'httpx_headers_value_parser.dart';

typedef _HttpxHeadersMap = CaseInsensitiveMap<HttpxHeaderValues>;

class HttpxHeaders {
  static const kSensitiveHeadersNames = <HttpxHeaderName>[
    HttpHeaders.cookieHeader,
    HttpHeaders.setCookieHeader,
    HttpHeaders.proxyAuthorizationHeader,
    HttpHeaders.authorizationHeader,
    HttpHeaders.wwwAuthenticateHeader,
    HttpHeaders.proxyAuthenticateHeader,
    r'api[-_]?key',
  ];

  // https://httpwg.org/specs/rfc9110.html#rfc.section.5.3
  static const kDefaultUnfoldableNames = <HttpxHeaderName>[
    HttpHeaders.setCookieHeader,
  ];

  static bool headerValuesEquals(HttpxHeaderValues a, HttpxHeaderValues b) {
    const unorderedEquality = DeepCollectionEquality.unordered();

    return unorderedEquality.equals(a, b);
  }

  static bool entriesEquals(HttpxHeadersEntries a, HttpxHeadersEntries b) {
    final keys = [...a.keys, ...b.keys];

    return keys.every(
      (key) =>
          a[key] != null &&
          b[key] != null &&
          HttpxHeaders.headerValuesEquals(a[key]!, b[key]!),
    );
  }

  factory HttpxHeaders([Iterable<String>? unfoldableNames]) =>
      HttpxHeaders._(unfoldableNames);

  HttpxHeaders._([Iterable<String>? unfoldableNames, _HttpxHeadersMap? map])
    : _unfoldableNames =
          unfoldableNames?.map((e) => e.toLowerCase()) ??
          kDefaultUnfoldableNames,
      _map = map ?? _HttpxHeadersMap();

  factory HttpxHeaders.fromMap(
    Map<HttpxHeaderName, dynamic> map, [
    Iterable<HttpxHeaderName>? unfoldableNames,
  ]) => HttpxHeaders._(unfoldableNames).copyWith(map);

  factory HttpxHeaders.fromHttpHeaders(
    HttpHeaders httpHeaders, [
    Iterable<String>? unfoldableNames,
  ]) {
    final instance = HttpxHeaders._(unfoldableNames);

    httpHeaders.forEach(instance.set);

    return instance;
  }

  final Iterable<HttpxHeaderName> _unfoldableNames;
  final _HttpxHeadersMap _map;
  bool _locked = false;

  bool get isEmpty => _map.keys.isEmpty;

  bool get isNotEmpty => !isEmpty;

  HttpxHeaderValues? operator [](HttpxHeaderName name) => _map[name];
  void operator []=(HttpxHeaderName name, HttpxHeaderValues? values) {
    if (values == null) {
      removeAll(name);
    } else {
      set(name, values);
    }
  }

  void lock() => _locked = true;

  Iterable<HttpxHeaderName> getKeys({bool lowerCasedNames = true}) {
    return lowerCasedNames ? _map.keys.map((e) => e.toLowerCase()) : _map.keys;
  }

  HttpxHeadersEntries getEntries({bool lowerCasedNames = true}) {
    return _map.map((key, value) {
      final lowerCasedName = key.toLowerCase();

      return MapEntry(lowerCasedNames ? lowerCasedName : key, value);
    });
  }

  HttpxHeadersFoldedEntries getFoldedEntries({bool lowerCasedNames = true}) {
    return Map.fromEntries(
      _map.entries.expand((element) {
        final lowerCasedName = element.key.toLowerCase();

        if (_unfoldableNames.contains(lowerCasedName)) {
          return element.value.map(
            (e) => MapEntry(lowerCasedNames ? lowerCasedName : element.key, e),
          );
        } else {
          return [
            MapEntry(
              lowerCasedNames ? lowerCasedName : element.key,
              HttpxHeaderValueParser.httpList(element.value),
            ),
          ];
        }
      }),
    );
  }

  bool contains(HttpxHeaderName name) => _map.containsKey(name);

  void add(
    HttpxHeaderName name,
    HttpxHeaderValue value, {
    bool ifNotPresent = false,
  }) => addAll(name, [value], ifNotPresent: ifNotPresent);

  void addAll(
    HttpxHeaderName name,
    HttpxHeaderValues values, {
    bool ifNotPresent = false,
  }) => set(name, [...this[name] ?? [], ...values], ifNotPresent: ifNotPresent);

  void set(
    HttpxHeaderName name,
    HttpxHeaderValues values, {
    bool ifNotPresent = false,
  }) {
    final parsedValues = values.expand(HttpxHeaderValueParser.parseHttpList);

    if (parsedValues.isEmpty) {
      removeAll(name);
    } else {
      if (_locked) {
        throw Exception('Headers are locked');
      }

      if (!ifNotPresent || !_map.containsKey(name)) {
        _map[name] = parsedValues;
      }
    }
  }

  void removeAll(HttpxHeaderName name) {
    if (_locked) {
      throw Exception('Headers are locked');
    }

    _map.remove(name);
  }

  void remove(HttpxHeaderName name, HttpxHeaderValue value) {
    final parsedValue = HttpxHeaderValueParser.parseHttpList(value);

    final values = this[name]?.toList() ?? [];
    set(name, values..removeWhere(parsedValue.contains));
  }

  void clear() {
    if (_locked) {
      throw Exception('Headers are locked');
    }

    _map.clear();
  }

  HttpxHeaders clone() =>
      HttpxHeaders._([..._unfoldableNames], _HttpxHeadersMap.from(_map));

  HttpxHeaders copyWith(Map<HttpxHeaderName, dynamic> map, {bool add = false}) {
    final instance = clone();

    map.forEach((name, value) {
      if (value is Iterable) {
        final value_ = value.map((e) => e.toString());
        if (add) {
          instance.addAll(name, value_);
        } else {
          instance.set(name, value_);
        }
      } else {
        if (add) {
          instance.add(name, value.toString());
        } else {
          instance.set(name, [value.toString()]);
        }
      }
    });

    return instance;
  }

  void mutateHttpHeaders(HttpHeaders httpHeaders, {bool clear = false}) {
    if (clear) {
      httpHeaders.clear();
    }

    for (final entry in _map.entries) {
      for (final value in entry.value) {
        httpHeaders.add(entry.key, value);
      }
    }
  }

  bool matchAll(HttpxHeadersEntries entries) {
    return entries.entries.every(
      (element) => headerValuesEquals(this[element.key] ?? [], element.value),
    );
  }

  @override
  String toString([
    bool hideSensitiveHeadersValues = true,
    int valueTruncateLength = 80,
  ]) {
    return getFoldedEntries(lowerCasedNames: false)
        .map<String, String>((key, value) {
          if (hideSensitiveHeadersValues &&
              kSensitiveHeadersNames.any(
                (element) =>
                    RegExp(element, caseSensitive: false).hasMatch(key),
              )) {
            // ignore: avoid-non-ascii-symbols
            return MapEntry(key, '… (sensitive, ${value.length} bytes hidden)');
          } else {
            return MapEntry(
              key,
              value.inspect(
                InspectOptions(maxStringLength: valueTruncateLength),
              ),
            );
          }
        })
        .inspect(
          const InspectOptions(mapKeyValueSep: ': ', preferCompact: false),
        );
  }
}
