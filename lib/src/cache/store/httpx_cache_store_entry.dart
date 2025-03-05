// SPDX-FileCopyrightText: © 2023 - 2024 Anthony Champagne <dev@anthonychampagne.fr>
//
// SPDX-License-Identifier: BSD-3-Clause

import '../../headers/httpx_headers.dart';
import '../../httpx_redirect_info.dart';
import '../../httpx_response.dart';

class HttpxCacheStoreEntry {
  final DateTime firstByteSentTime;
  final Uri uri;
  final HttpxHeaders requestHeaders;
  final DateTime firstByteReceivedTime;
  final Iterable<HttpxRedirectInfo> redirects;
  final int status;
  final String? statusText;
  final HttpxHeaders responseHeaders;
  final List<int>? responseBody;

  const HttpxCacheStoreEntry({
    required this.firstByteSentTime,
    required this.uri,
    required this.requestHeaders,
    required this.firstByteReceivedTime,
    required this.redirects,
    required this.status,
    required this.statusText,
    required this.responseHeaders,
    required this.responseBody,
  });

  factory HttpxCacheStoreEntry.from(HttpxCacheStoreEntry other) =>
      HttpxCacheStoreEntry(
        firstByteSentTime: other.firstByteSentTime,
        uri: other.uri,
        requestHeaders: other.requestHeaders.clone(),
        firstByteReceivedTime: other.firstByteReceivedTime,
        redirects: [...other.redirects],
        status: other.status,
        statusText: other.statusText,
        responseHeaders: other.responseHeaders.clone(),
        responseBody:
            other.responseBody == null ? null : [...other.responseBody!],
      );

  factory HttpxCacheStoreEntry.fromResponse({
    required Uri uri,
    required HttpxHeaders requestHeaders,
    required DateTime firstByteSentTime,
    required HttpxResponse response,
    required List<int>? responseBody,
  }) => HttpxCacheStoreEntry(
    firstByteSentTime: firstByteSentTime,
    uri: uri,
    requestHeaders: requestHeaders.clone(),
    firstByteReceivedTime: response.firstByteReceivedTime,
    redirects: [...response.redirects],
    status: response.status,
    statusText: response.statusText,
    responseHeaders: response.headers.clone(),
    responseBody: responseBody,
  );

  HttpxCacheStoreEntry clone() => HttpxCacheStoreEntry.from(this);
}
