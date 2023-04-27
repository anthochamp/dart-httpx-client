// Copyright 2023, Anthony Champagne. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:ac_dart_essentials/ac_dart_essentials.dart';

import '../headers/httpx_headers.dart';
import '../httpx_redirect_info.dart';
import '../httpx_response.dart';
import '../httpx_typedefs.dart';

class HttpxBuiltinHttpResponse extends Stream<List<int>>
    implements HttpxResponse {
  final String method;
  final Uri uri;

  @override
  final DateTime firstByteReceivedTime;

  final HttpxLogCallback? logCallback;

  HttpxBuiltinHttpResponse(
    this._httpClientResponse, {
    required this.method,
    required this.uri,
    required this.firstByteReceivedTime,
    required this.logCallback,
  }) {
    _headers = HttpxHeaders.fromHttpHeaders(_httpClientResponse.headers);

    logCallback?.call('[$method $uri] Received response status and headers: ${{
      'redirects': _httpClientResponse.redirects,
      'connectionInfo': {
        'localPort': _httpClientResponse.connectionInfo?.localPort,
        'remoteAddress': _httpClientResponse.connectionInfo?.remoteAddress,
        'remotePort': _httpClientResponse.connectionInfo?.remotePort,
      },
      'statusCode': _httpClientResponse.statusCode,
      'reasonPhrase': _httpClientResponse.reasonPhrase,
      'headers': _headers,
      'persistantConnection': _httpClientResponse.persistentConnection,
    }.inspect()}');

    unawaited(_httpClientResponse
        .pipe(_streamController)
        .then((_) => logCallback?.call(
              '[$method $uri] Response reception completed.',
            )));
  }

  late final HttpxHeaders _headers;
  final HttpClientResponse _httpClientResponse;

  // closed by pipe()
  // ignore: close_sinks
  final _streamController = StreamController<List<int>>();

  @override
  Iterable<HttpxRedirectInfo> get redirects =>
      _httpClientResponse.redirects.map(HttpxRedirectInfo.from);

  @override
  HttpxHeaders get headers => _headers;

  @override
  int get status => _httpClientResponse.statusCode;

  @override
  String get statusText => _httpClientResponse.reasonPhrase;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      _streamController.stream.listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );

  @override
  // ignore: no-empty-block
  void dispose() {
    // do nothing
  }
}
