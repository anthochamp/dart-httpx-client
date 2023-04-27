// Copyright 2023, Anthony Champagne. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:ac_dart_essentials/ac_dart_essentials.dart';

import '../headers/extensions/httpx_headers_cache_extension.dart';
import '../headers/extensions/httpx_headers_proxy_extension.dart';
import '../headers/httpx_headers.dart';
import '../headers/httpx_headers_typedefs.dart';
import '../httpx_response.dart';
import 'store/httpx_cache_store_entry.dart';

// https://datatracker.ietf.org/doc/html/rfc7231#section-4.2.1
const kSafeHttpMethods = ['GET', 'HEAD', 'OPTIONS', 'TRACE'];

// https://datatracker.ietf.org/doc/html/rfc5861#section-4
const kStaleIfErrorStatusCodes = [500, 502, 503, 504];

class HttpxCacheUtilities {
  // https://datatracker.ietf.org/doc/html/rfc7234#section-4.1
  static HttpxHeadersEntries? composeVaryingRequestHeadersEntries({
    required HttpxHeaders requestHeaders,
    required HttpxHeaders responseHeaders,
  }) {
    final vary = responseHeaders.getVary(lowerCasedNames: true);

    if (vary == null) {
      return {};
    }

    if (vary.any((element) => element == '*')) {
      return null;
    }

    return requestHeaders.getEntries()
      ..removeWhere((key, _) => !vary.contains(key));
  }

  // https://datatracker.ietf.org/doc/html/rfc7234#section-4.1
  static Iterable<HttpxCacheStoreEntry> selectPreferredStoreEntries({
    required HttpxHeaders requestHeaders,
    required Iterable<HttpxCacheStoreEntry> entries,
  }) {
    var preferredEntries = entries;

    // https://www.rfc-editor.org/rfc/rfc9110.html#name-content-negotiation-fields
    // TODO: implement Accept, Accept-Charset, Accept-Encoding, Accept-Language (with q values)

    // https://www.rfc-editor.org/rfc/rfc9110.html#section-12.5.5

    preferredEntries = preferredEntries.where((element) {
      final elementVaryingHeadersEntries =
          HttpxCacheUtilities.composeVaryingRequestHeadersEntries(
        requestHeaders: element.requestHeaders,
        responseHeaders: element.responseHeaders,
      );
      final incomingVaryingHeadersEntries =
          HttpxCacheUtilities.composeVaryingRequestHeadersEntries(
        requestHeaders: requestHeaders,
        responseHeaders: element.responseHeaders,
      );

      if (elementVaryingHeadersEntries == null ||
          incomingVaryingHeadersEntries == null) {
        return false;
      }

      return HttpxHeaders.entriesEquals(
        elementVaryingHeadersEntries,
        incomingVaryingHeadersEntries,
      );
    });

    // https://datatracker.ietf.org/doc/html/rfc7234#section-4.1
    // When more than one suitable response is stored, a cache MUST use the
    // most recent response (as determined by the Date header field).
    if (preferredEntries.isNotEmpty) {
      final nullDate = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

      preferredEntries = preferredEntries.toList()
        ..sort((a, b) {
          final dateA = a.responseHeaders.getDate() ?? nullDate;
          final dateB = b.responseHeaders.getDate() ?? nullDate;

          return dateA.compareTo(dateB);
        })
        ..reversed;

      final mostRecentEntryDate =
          preferredEntries.first.responseHeaders.getDate() ?? nullDate;

      preferredEntries = preferredEntries.takeWhile(
        (value) => value.responseHeaders.getDate() == mostRecentEntryDate,
      );
    }

    return preferredEntries;
  }

  // https://datatracker.ietf.org/doc/html/rfc7231#section-7.1.1.2
  static DateTime composeGeneratedAt({
    required HttpxHeaders responseHeaders,
    required DateTime firstByteReceivedTime,
  }) =>
      responseHeaders.getDate() ?? firstByteReceivedTime;

  // https://datatracker.ietf.org/doc/html/rfc7234#section-4.2.1
  static Duration? computeFreshnessLifetime({
    required HttpxHeaders responseHeaders,
    required DateTime firstByteReceivedTime,
  }) {
    final maxAgeValue = responseHeaders.getCacheControl()?.maxAgeValue;
    if (maxAgeValue != null) {
      return maxAgeValue;
    }

    final expires = responseHeaders.getExpires();
    if (expires != null) {
      final generatedAt = composeGeneratedAt(
        responseHeaders: responseHeaders,
        firstByteReceivedTime: firstByteReceivedTime,
      );

      return expires.difference(generatedAt);
    }

    return null;
  }

  // https://datatracker.ietf.org/doc/html/rfc7234#section-4.2.2
  static Duration? computeHeuristicFreshnessLifetime({
    required int status,
    required HttpxHeaders responseHeaders,
    required DateTime firstByteReceivedTime,
    required Iterable<int> cacheableStatusCode,
  }) {
    if (cacheableStatusCode.contains(status)) {
      final lastModified = responseHeaders.getLastModified();

      if (lastModified != null) {
        final generatedAt = composeGeneratedAt(
          responseHeaders: responseHeaders,
          firstByteReceivedTime: firstByteReceivedTime,
        );

        final heuristicExpires = DateTime.fromMillisecondsSinceEpoch(
          ((generatedAt.millisecondsSinceEpoch -
                      lastModified.millisecondsSinceEpoch) *
                  0.1)
              .floor(),
        );

        return heuristicExpires.difference(generatedAt);
      }
    }

    return null;
  }

  // https://datatracker.ietf.org/doc/html/rfc7234#section-4.2.3
  static Duration computeCurrentAge({
    required DateTime referenceTime,
    required HttpxHeaders responseHeaders,
    required DateTime firstByteReceivedTime,
    required DateTime firstByteSentTime,
  }) {
    final ageValue = responseHeaders.getAge() ?? 0;

    final responseDelay =
        firstByteReceivedTime.difference(firstByteSentTime).inSeconds;

    final correctedAgeValue = ageValue + responseDelay;

    final hasHttp1_0 = responseHeaders.getVia()?.any(
              (element) =>
                  (element.protocolName == null ||
                      element.protocolName!.toUpperCase() == 'HTTP') &&
                  element.protocolVersion == '1.0',
            ) ??
        false;

    int correctedInitialAge;
    if (hasHttp1_0) {
      final dateValue = composeGeneratedAt(
        responseHeaders: responseHeaders,
        firstByteReceivedTime: firstByteReceivedTime,
      );

      final apparentAge =
          max(0, firstByteReceivedTime.difference(dateValue).inSeconds);

      correctedInitialAge = max(apparentAge, correctedAgeValue);
    } else {
      correctedInitialAge = correctedAgeValue;
    }

    final residentTime = referenceTime.difference(firstByteSentTime).inSeconds;

    return Duration(seconds: correctedInitialAge + residentTime);
  }

  // https://datatracker.ietf.org/doc/html/rfc5861#section-3
  static Duration? computeStaleWhileRevalidateLifetime({
    required HttpxCacheControl? responseCacheControl,
  }) {
    final staleWhileRevalidateValue =
        responseCacheControl?.staleWhileRevalidateValue;
    if (staleWhileRevalidateValue != null) {
      final maxAgeValue = responseCacheControl?.maxAgeValue;
      if (maxAgeValue != null) {
        return DurationUtil.add(staleWhileRevalidateValue, maxAgeValue);
      }
    }

    return null;
  }

  // https://datatracker.ietf.org/doc/html/rfc5861#section-4
  static Duration? computeStaleIfErrorLifetime({
    required HttpxCacheControl? requestCacheControl,
    required HttpxCacheControl? responseCacheControl,
  }) {
    final staleIfErrorMinValue = DurationUtil.min(
      requestCacheControl?.staleIfErrorValue,
      responseCacheControl?.staleIfErrorValue,
    );

    if (staleIfErrorMinValue != null) {
      final maxAgeValue = responseCacheControl?.maxAgeValue;
      if (maxAgeValue != null) {
        return DurationUtil.add(staleIfErrorMinValue, maxAgeValue);
      }
    }

    return null;
  }

  // https://datatracker.ietf.org/doc/html/rfc7234#section-4.2
  static Duration? computeFreshness({
    required Duration? freshnessLifetime,
    required Duration currentAge,
  }) =>
      DurationUtil.substract(freshnessLifetime, currentAge);

  static bool computeIsStale({
    required Duration currentAge,
    required Duration? freshness,
    required HttpxCacheControl? requestCacheControl,
    required HttpxCacheControl? responseCacheControl,
  }) {
    if (freshness == null || freshness <= Duration.zero) {
      return true;
    }

    // https://datatracker.ietf.org/doc/html/rfc7234#section-5.2.1.1
    // https://datatracker.ietf.org/doc/html/rfc7234#section-5.2.2.8
    final maxAgeMinValue = DurationUtil.min(
      requestCacheControl?.maxAgeValue,
      responseCacheControl?.maxAgeValue,
    );
    if (maxAgeMinValue != null && maxAgeMinValue < currentAge) {
      return false;
    }

    return false;
  }

  static bool computeStaleServeAllowed({
    required HttpxCacheControl? requestCacheControl,
    required Duration? freshness,
  }) {
    // https://datatracker.ietf.org/doc/html/rfc7234#section-5.2.1.2
    if (requestCacheControl?.maxStale == true) {
      final maxStaleValue = requestCacheControl?.maxStaleValue;
      if (maxStaleValue == null) {
        return true;
      }

      final staleness = freshness == null ? null : freshness * -1;
      if (staleness != null && staleness < maxStaleValue) {
        return true;
      }
    }

    return false;
  }

  static bool computeMustRevalidate({
    required bool requestPragmaNoCache,
    required HttpxCacheControl? requestCacheControl,
    required HttpxCacheControl? responseCacheControl,
    required Duration? freshness,
    required bool isStale,
  }) {
    // https://datatracker.ietf.org/doc/html/rfc7234#section-5.2.1.3
    final minFreshValue = requestCacheControl?.minFreshValue;
    if (minFreshValue != null &&
        (freshness == null || freshness < minFreshValue)) {
      return true;
    }

    // https://datatracker.ietf.org/doc/html/rfc7234#section-5.2.1.4
    if (requestCacheControl?.noCache != null) {
      return true;
    }

    // https://datatracker.ietf.org/doc/html/rfc7234#section-5.2.2.1
    if (isStale && responseCacheControl?.mustRevalidate == true) {
      return true;
    }

    // https://datatracker.ietf.org/doc/html/rfc7234#section-5.2.2.2
    if (responseCacheControl?.noCache == true &&
        responseCacheControl?.noCacheValues.isEmpty == true) {
      return true;
    }

    // https://datatracker.ietf.org/doc/html/rfc7234#section-5.4
    if (requestCacheControl == null && requestPragmaNoCache) {
      return true;
    }

    return false;
  }

  // https://datatracker.ietf.org/doc/html/rfc7234#section-3
  static bool isCacheable({
    required String method,
    required HttpxHeaders requestHeaders,
    required HttpxResponse response,
    required Iterable<String> cacheableHttpMethods,
    required Iterable<int> cacheableStatusCode,
  }) {
    if (!cacheableHttpMethods.contains(method)) {
      return false;
    }

    final requestCacheControl = requestHeaders.getCacheControl();
    final responseCacheControl = response.headers.getCacheControl();

    // https://datatracker.ietf.org/doc/html/rfc7234#section-5.2.1.5
    // https://datatracker.ietf.org/doc/html/rfc7234#section-5.2.2.3
    if (requestCacheControl?.noStore == true ||
        responseCacheControl?.noStore == true) {
      return false;
    }

    if (response.headers.getExpires() == null &&
        responseCacheControl?.maxAgeValue == null &&
        responseCacheControl?.public == null &&
        !cacheableStatusCode.contains(response.status)) {
      return false;
    }

    // + no need to cache a response we won't be able to match later
    final vary = response.headers.getVary();
    if (vary?.any((element) => element == '*') == true) {
      return false;
    }

    return true;
  }
}
