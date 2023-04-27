// Copyright 2023, Anthony Champagne. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../headers/extensions/httpx_headers_cache_extension.dart';
import '../headers/httpx_headers.dart';
import '../httpx_redirect_info.dart';
import '../httpx_response.dart';
import 'httpx_cache_context.dart';
import 'store/httpx_cache_store_entry.dart';

class HttpxCacheResponse extends Stream<List<int>> implements HttpxResponse {
  @override
  final DateTime firstByteReceivedTime;

  @override
  final Iterable<HttpxRedirectInfo> redirects;

  @override
  final int status;

  @override
  final String? statusText;

  @override
  final HttpxHeaders headers;

  final Stream<List<int>> stream;

  HttpxCacheResponse._({
    required this.firstByteReceivedTime,
    required this.redirects,
    required this.status,
    required this.statusText,
    required this.headers,
    required this.stream,
  });

  factory HttpxCacheResponse.gatewayTimeout() {
    return HttpxCacheResponse._(
      firstByteReceivedTime: DateTime.now(),
      redirects: [],
      status: HttpStatus.gatewayTimeout,
      statusText: null,
      headers: HttpxHeaders(),
      stream: const Stream.empty(),
    );
  }

  factory HttpxCacheResponse.from({
    required HttpxCacheStoreEntry storeEntry,
    required HttpxCacheContext context,
    required bool? validationFailed,
  }) {
    final instance = HttpxCacheResponse._(
      firstByteReceivedTime: storeEntry.firstByteReceivedTime,
      redirects: storeEntry.redirects,
      status: storeEntry.status,
      statusText: storeEntry.statusText,
      headers: storeEntry.responseHeaders.clone(),
      stream: Stream.fromIterable(
        storeEntry.responseBody == null ? [] : [storeEntry.responseBody!],
      ),
    );

    instance.headers.setAge(context.currentAge.inSeconds);

    // https://datatracker.ietf.org/doc/html/rfc7234#section-5.5.1
    if (context.isStale) {
      instance.headers.add(
        HttpHeaders.warningHeader,
        '110 httpx "Response is Stale"',
      );
    }

    if (validationFailed != null && validationFailed) {
      // https://datatracker.ietf.org/doc/html/rfc7234#section-5.5.2
      instance.headers.add(
        HttpHeaders.warningHeader,
        '111 httpx "Revalidation Failed"',
      );
    }

    // https://datatracker.ietf.org/doc/html/rfc7234#section-5.5.4
    if (context.isHeuristicFreshnessLifetime == true &&
        context.freshnessLifetime != null &&
        context.freshnessLifetime! >= const Duration(days: 1) &&
        context.currentAge >= const Duration(days: 1)) {
      instance.headers.add(
        HttpHeaders.warningHeader,
        '113 httpx "Heuristic Expiration"',
      );
    }

    // https://datatracker.ietf.org/doc/html/rfc7234#section-5.2.2.2
    if (context.isStale && validationFailed != false) {
      for (final noCacheValue
          in context.responseCacheControl?.noCacheValues ?? <String>[]) {
        instance.headers.removeAll(noCacheValue);
      }
    }

    return instance;
  }

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      stream.listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );

  @override
  // ignore: no-empty-block
  void dispose() {
    // does nothing
  }
}
