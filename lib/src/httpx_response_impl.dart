// SPDX-FileCopyrightText: © 2023 - 2024 Anthony Champagne <dev@anthonychampagne.fr>
//
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';

import 'cache/httpx_cache.dart';
import 'headers/httpx_headers.dart';
import 'httpx_redirect_info.dart';
import 'httpx_response.dart';

class HttpxResponseImpl extends Stream<List<int>> implements HttpxResponse {
  final HttpxResponse response;
  final WeakReference<HttpxCache> cache;
  final String method;
  final Uri uri;
  final HttpxHeaders requestHeaders;
  final DateTime firstByteSentTime;

  HttpxResponseImpl({
    required this.method,
    required this.uri,
    required this.requestHeaders,
    required this.firstByteSentTime,
    required this.response,
    required this.cache,
  }) {
    response.listen(
      (data) {
        if (!_streamController.isClosed) {
          _streamController.add(data);
        }
        _cacheStreamController.add(data);
      },
      onError: (error, stackTrace) {
        if (!_streamController.isClosed) {
          _streamController.addError(error, stackTrace);
        }
        _cacheStreamController.addError(error, stackTrace);
      },
      onDone: () {
        unawaited(_streamController.close());

        unawaited(_cacheStreamController.stream.fold(
          <int>[],
          (previous, element) => previous..addAll(element),
        ).then((body) async {
          await cache.target?.update(
            method: method,
            uri: uri,
            requestHeaders: requestHeaders,
            firstByteSentTime: firstByteSentTime,
            response: response,
            responseBody: body,
          );
        }));

        unawaited(_cacheStreamController.close());
      },
      cancelOnError: false,
    );
  }

  final _streamController = StreamController<List<int>>();
  final _cacheStreamController = StreamController<List<int>>();

  @override
  DateTime get firstByteReceivedTime => response.firstByteReceivedTime;

  @override
  HttpxHeaders get headers => response.headers;

  @override
  Iterable<HttpxRedirectInfo> get redirects => response.redirects;

  @override
  int get status => response.status;

  @override
  String? get statusText => response.statusText;

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
  FutureOr<void> dispose() async {
    await _streamController.close();
  }
}
