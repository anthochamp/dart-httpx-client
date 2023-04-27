// Copyright 2023, Anthony Champagne. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'cache/httpx_cache.dart';
import 'cache/httpx_cache_policy.dart';
import 'headers/httpx_headers.dart';
import 'httpx_request.dart';
import 'httpx_response.dart';
import 'httpx_response_impl.dart';
import 'httpx_typedefs.dart';

class HttpxRequestImpl implements HttpxRequest {
  final HttpxCachePolicy cachePolicy;
  @override
  final int maxRedirects;
  final Duration? connectionTimeout;
  final HttpxCreateNetworkRequestCallback createNetworkRequestCallback;
  final WeakReference<HttpxCache> cache;

  HttpxRequestImpl({
    required String method,
    required Uri uri,
    required HttpxHeaders headers,
    required this.cachePolicy,
    required this.maxRedirects,
    required this.connectionTimeout,
    required this.createNetworkRequestCallback,
    required this.cache,
  })  : _method = method,
        _uri = uri,
        _headers = headers;

  final String _method;
  final Uri _uri;
  final HttpxHeaders _headers;
  HttpxResponse? _response;
  HttpxRequest? _request;
  bool _hasUnflushedData = false;

  @override
  String get method => _request?.method ?? _method;

  @override
  Uri get uri => _request?.uri ?? _uri;

  @override
  HttpxHeaders get headers => _request?.headers ?? _headers;

  @override
  int get dataSent => _request?.dataSent ?? 0;

  @override
  bool get closed => _response != null;

  @override
  DateTime? get firstByteSentTime => _request?.firstByteSentTime;

  @override
  Future<void> write(List<int> encodedData) async {
    if (closed) {
      throw Exception('Request is closed');
    }

    await _open();

    _hasUnflushedData |= encodedData.isNotEmpty;

    return _request!.write(encodedData);
  }

  @override
  Future<void> flush() async {
    if (closed) {
      throw Exception('Request is closed');
    }

    if (_hasUnflushedData) {
      await _request!.flush();
    }
  }

  @override
  Future<HttpxResponse> close([Duration? timeout]) async {
    if (_response != null) {
      return _response!;
    }

    if (_request == null) {
      _response = await cache.target?.process(
        request: this,
        timeout: timeout,
        connectionTimeout: connectionTimeout,
        cachePolicy: cachePolicy,
      );
    }

    if (_response == null) {
      await _open();

      final requestResponse = await _request!.close(timeout);

      _response = HttpxResponseImpl(
        method: _request!.method,
        uri: _request!.uri,
        requestHeaders: _request!.headers,
        firstByteSentTime: _request!.firstByteSentTime!,
        response: requestResponse,
        cache: cache,
      );
    }

    return _response!;
  }

  Future<void> _open() async {
    _request ??= await createNetworkRequestCallback(
      method: _method,
      uri: _uri,
      headers: _headers,
      maxRedirects: maxRedirects,
      connectionTimeout: connectionTimeout,
    );
  }
}
