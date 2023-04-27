// Copyright 2023, Anthony Champagne. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:http2/http2.dart';

import '../headers/httpx_headers.dart';

class HttpxHttp2Utilities {
  static Map<String, String> http2HeadersDecode(HeadersStreamMessage message) =>
      Map.fromEntries(message.headers
          .map((e) => MapEntry(utf8.decode(e.name), utf8.decode(e.value))));

  static List<Header> http2HeadersEncode({
    required Uri uri,
    required String method,
    HttpxHeaders? headers,
  }) {
    final headers_ = headers?.clone() ?? HttpxHeaders();

    String? authority;

    final host = headers_[HttpHeaders.hostHeader]?.single;
    if (host == null) {
      authority = uri.host + (uri.hasPort ? ':${uri.port}' : '');
    } else {
      authority = host;

      headers_.removeAll(HttpHeaders.hostHeader);
    }

    String path = uri.path +
        (uri.hasQuery ? '?${uri.query}' : '') +
        (uri.hasFragment ? '#${uri.fragment}' : '');
    if (path.isEmpty && path == '/') {
      path = method == 'OPTIONS' ? '*' : '/';
    }

    return [
      Header.ascii(':method', method),
      Header.ascii(':scheme', uri.scheme),
      Header.ascii(':authority', authority),
      Header.ascii(':path', path),
      ...headers_
          .getFoldedEntries(lowerCasedNames: true)
          .entries
          .map((header) => Header.ascii(header.key, header.value)),
    ];
  }
}
