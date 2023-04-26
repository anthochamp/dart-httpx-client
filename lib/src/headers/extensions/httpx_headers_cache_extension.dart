import 'dart:io';

import 'package:anthochamp_dart_essentials/dart_essentials.dart';
import 'package:httpx_client/src/headers/extensions/httpx_headers_typed_extension.dart';
import 'package:httpx_client/src/headers/httpx_headers.dart';
import 'package:httpx_client/src/headers/httpx_headers_typedefs.dart';
import 'package:httpx_client/src/headers/httpx_headers_value_parser.dart';

// https://www.iana.org/assignments/http-cache-directives/http-cache-directives.xhtml
class HttpxCacheControl {
  // https://www.rfc-editor.org/rfc/rfc8246.html#section-2
  final bool immutable;

  // https://www.rfc-editor.org/rfc/rfc9111.html#name-cache-control
  final Duration? maxAgeValue;
  final bool maxStale;
  final Duration? maxStaleValue;
  final Duration? minFreshValue;
  final bool noCache;
  final Iterable<HttpxHeaderName> noCacheValues;
  final bool noStore;
  final bool noTransform;
  final bool onlyIfCached;
  final bool mustRevalidate;
  final bool mustUnderstand;
  final bool public;
  final bool private;
  final Iterable<HttpxHeaderName> privateValues;
  final bool proxyRevalidate;
  final Duration? sMaxAgeValue;

  // https://www.rfc-editor.org/rfc/rfc5861.html#section-3
  final Duration? staleWhileRevalidateValue;
  // https://www.rfc-editor.org/rfc/rfc5861.html#section-4
  final Duration? staleIfErrorValue;

  HttpxCacheControl({
    this.immutable = false,
    this.maxAgeValue,
    this.maxStale = false,
    this.maxStaleValue,
    this.minFreshValue,
    this.noCache = false,
    this.noCacheValues = const [],
    this.noStore = false,
    this.noTransform = false,
    this.onlyIfCached = false,
    this.mustRevalidate = false,
    this.mustUnderstand = false,
    this.public = false,
    this.private = false,
    this.privateValues = const [],
    this.proxyRevalidate = false,
    this.sMaxAgeValue,
    this.staleWhileRevalidateValue,
    this.staleIfErrorValue,
  });

  factory HttpxCacheControl.fromMap(Map<String, String?> map) {
    return HttpxCacheControl(
      immutable: map.containsKey('immutable'),
      maxAgeValue: map.containsKey('max-age')
          ? Duration(seconds: int.parse(map['max-age']!))
          : null,
      maxStale: map.containsKey('max-stale'),
      maxStaleValue: map['max-stale'] != null
          ? Duration(seconds: int.parse(map['max-stale']!))
          : null,
      minFreshValue: map.containsKey('max-fresh')
          ? Duration(seconds: int.parse(map['max-fresh']!))
          : null,
      noCache: map.containsKey('no-cache'),
      noCacheValues: map['no-cache'] != null
          ? HttpxHeaderValueParser.parseHttpList(
              HttpxHeaderValueParser.parseQuotedString(map['no-cache']!),
            )
          : const [],
      noStore: map.containsKey('no-store'),
      noTransform: map.containsKey('no-transform'),
      onlyIfCached: map.containsKey('only-if-cached'),
      mustRevalidate: map.containsKey('must-revalidate'),
      mustUnderstand: map.containsKey('must-understand'),
      public: map.containsKey('public'),
      private: map.containsKey('private'),
      privateValues: map['private'] != null
          ? HttpxHeaderValueParser.parseHttpList(
              HttpxHeaderValueParser.parseQuotedString(map['private']!),
            )
          : const [],
      proxyRevalidate: map.containsKey('proxy-revalidate'),
      sMaxAgeValue: map.containsKey('s-maxage')
          ? Duration(seconds: int.parse(map['s-maxage']!))
          : null,
      staleWhileRevalidateValue: map.containsKey('stale-while-revalidate')
          ? Duration(seconds: int.parse(map['stale-while-revalidate']!))
          : null,
      staleIfErrorValue: map.containsKey('stale-if-error')
          ? Duration(seconds: int.parse(map['stale-if-error']!))
          : null,
    );
  }

  factory HttpxCacheControl.fromHeaderValues(HttpxHeaderValues headerValues) {
    final entries = headerValues.expand<MapEntry<String, String?>>((e) {
      final tmp = e.split('=');

      return [
        MapEntry(tmp.first, tmp.length > 1 ? tmp.skip(1).join('=') : null),
      ];
    });

    return HttpxCacheControl.fromMap(Map<String, String?>.fromEntries(entries));
  }

  Map<String, String?> toMap() => {
        if (immutable) 'immutable': null,
        if (maxAgeValue != null) 'max-age': maxAgeValue!.inSeconds.toString(),
        if (maxStale) 'max-stale': maxStaleValue?.inSeconds.toString(),
        if (minFreshValue != null)
          'min-fresh': minFreshValue!.inSeconds.toString(),
        if (noCache)
          'no-cache': noCacheValues.isEmpty
              ? null
              : HttpxHeaderValueParser.quotedString(
                  HttpxHeaderValueParser.httpList(noCacheValues),
                ),
        if (noStore) 'no-store': null,
        if (noTransform) 'no-transform': null,
        if (onlyIfCached) 'only-if-cached': null,
        if (mustRevalidate) 'must-revalidate': null,
        if (mustUnderstand) 'must-understand': null,
        if (public) 'public': null,
        if (private)
          'private': privateValues.isEmpty
              ? null
              : HttpxHeaderValueParser.quotedString(
                  HttpxHeaderValueParser.httpList(privateValues),
                ),
        if (proxyRevalidate) 'proxy-revalidate': null,
        if (sMaxAgeValue != null)
          's-maxage': sMaxAgeValue!.inSeconds.toString(),
        if (staleWhileRevalidateValue != null)
          'stale-while-revalidate':
              staleWhileRevalidateValue!.inSeconds.toString(),
        if (staleIfErrorValue != null)
          'stale-if-error': staleIfErrorValue!.inSeconds.toString(),
      };

  HttpxHeaderValues toHeaderValues() {
    return toMap().entries.map(
          (e) => '${e.key}${e.value == null ? '' : '=${e.value}'}',
        );
  }

  @override
  String toString() => toMap().inspect();
}

extension HttpxHeadersCacheExtension on HttpxHeaders {
  // https://datatracker.ietf.org/doc/html/rfc7234#section-5.1
  int? getAge() => getIntField(HttpHeaders.ageHeader);
  void setAge(int? age) => setIntField(HttpHeaders.ageHeader, age);

  // https://datatracker.ietf.org/doc/html/rfc7234#section-5.2
  HttpxCacheControl? getCacheControl() {
    final values = this[HttpHeaders.cacheControlHeader];

    return values == null ? null : HttpxCacheControl.fromHeaderValues(values);
  }

  void setCacheControl(HttpxCacheControl? cacheControl) =>
      this[HttpHeaders.cacheControlHeader] = cacheControl?.toHeaderValues();

  // https://datatracker.ietf.org/doc/html/rfc7234#section-5.3
  DateTime? getExpires() => getDateTimeField(HttpHeaders.expiresHeader);

  // https://datatracker.ietf.org/doc/html/rfc7234#section-5.4
  HttpxHeaderValues? getPragma() => this[HttpHeaders.pragmaHeader];
  bool hasPragmaNoCache() => getPragma()?.contains('no-cache') ?? false;

  // https://datatracker.ietf.org/doc/html/rfc7234#section-5.5
  HttpxHeaderValues? getWarning() => this[HttpHeaders.warningHeader];
  // TODO: void addWarningValue()
  // TODO: void remWarningValue(int code)

  DateTime? getDate() => getDateTimeField(HttpHeaders.dateHeader);

  DateTime? getLastModified() =>
      getDateTimeField(HttpHeaders.lastModifiedHeader);

  String? getEtag() => this[HttpHeaders.etagHeader]?.single;
  void setEtag(String? etag) =>
      this[HttpHeaders.etagHeader] = etag == null ? null : [etag];

  // https://www.rfc-editor.org/rfc/rfc7231.html#section-7.1.4
  Iterable<HttpxHeaderName>? getVary({bool lowerCasedNames = true}) {
    final vary = this[HttpHeaders.varyHeader];

    if (lowerCasedNames) {
      return vary?.map((e) => e.toLowerCase());
    } else {
      return vary;
    }
  }
}
