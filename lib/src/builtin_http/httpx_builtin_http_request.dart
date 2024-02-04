// SPDX-FileCopyrightText: © 2023 - 2024 Anthony Champagne <dev@anthonychampagne.fr>
//
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:convert';
import 'dart:io';

import 'package:ac_dart_essentials/ac_dart_essentials.dart';
import 'package:async/async.dart';

import '../headers/httpx_headers.dart';
import '../httpx_request.dart';
import '../httpx_response.dart';
import '../httpx_typedefs.dart';
import 'httpx_builtin_http_response.dart';

class HttpxBuiltinHttpRequest implements HttpxRequest {
  @override
  final String method;

  @override
  final Uri uri;

  @override
  final int maxRedirects;

  final bool persistantConnection;
  final HttpxLogCallback? logCallback;

  HttpxBuiltinHttpRequest(
    this._httpClient, {
    required this.method,
    required this.uri,
    required this.headers,
    required this.maxRedirects,
    required this.persistantConnection,
    required this.logCallback,
  });

  final HttpClient _httpClient;
  final _openMemoizer = AsyncMemoizer<HttpClientRequest>();
  final _closeMemoizer = AsyncMemoizer<HttpxResponse>();
  DateTime? _firstByteSentTime;
  bool _unflushedData = false;

  @override
  int dataSent = 0;

  @override
  HttpxHeaders headers;

  @override
  bool get closed => _closeMemoizer.hasRun;

  @override
  DateTime? get firstByteSentTime => _firstByteSentTime;

  @override
  Future<void> write(List<int> encodedData) {
    return _open().then((httpClientRequest) {
      logCallback?.call(
        '[$method $uri] Writing ${encodedData.length} bytes of data...',
      );

      httpClientRequest.add(encodedData);

      dataSent += encodedData.length;
      _unflushedData |= encodedData.isNotEmpty;
      _firstByteSentTime ??= DateTime.now();

      logCallback?.call(
        '[$method $uri] ${encodedData.length} bytes of data written:\n${const AsciiDecoder(allowInvalid: true).convert(encodedData).inspect()}',
      );
    });
  }

  @override
  Future<void> flush() async {
    if (!_unflushedData) {
      return;
    }

    return _open().then((httpClientRequest) async {
      logCallback?.call('[$method $uri] Flushing data...');

      await httpClientRequest.flush();
      _unflushedData = false;

      logCallback?.call('[$method $uri] Data flushed.');
    });
  }

  @override
  Future<HttpxResponse> close([Duration? timeout]) =>
      _closeMemoizer.runOnce(() async {
        return _open().then((httpClientRequest) async {
          logCallback?.call('[$method $uri] Closing request...');

          _firstByteSentTime ??= DateTime.now();

          var httpClientResponseFuture = httpClientRequest.close();

          if (timeout != null) {
            httpClientResponseFuture =
                httpClientResponseFuture.timeout(timeout);
          }

          final httpClientResponse = await httpClientResponseFuture;

          logCallback?.call('[$method $uri] Request closed.');

          return HttpxBuiltinHttpResponse(
            httpClientResponse,
            method: method,
            uri: uri,
            firstByteReceivedTime: DateTime.now(),
            logCallback: logCallback,
          );
        });
      });

  Future<HttpClientRequest> _open() => _openMemoizer.runOnce(() async {
        logCallback?.call('[$method $uri] Opening request...');

        final httpClientRequest = await _httpClient.openUrl(method, uri);

        httpClientRequest.maxRedirects = maxRedirects;
        httpClientRequest.followRedirects = maxRedirects != 0;
        httpClientRequest.persistentConnection = persistantConnection;

        headers.mutateHttpHeaders(httpClientRequest.headers, clear: true);

        headers = HttpxHeaders.fromHttpHeaders(httpClientRequest.headers);
        headers.lock();

        logCallback?.call('[$method $uri] Request opened.');

        return httpClientRequest;
      });
}
