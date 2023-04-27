// Copyright 2023, Anthony Champagne. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:http2/http2.dart' as http2;

import 'cache/httpx_cache_policy.dart';
import 'cache/store/httpx_cache_store.dart';
import 'headers/httpx_headers.dart';
import 'httpx_client_impl.dart';
import 'httpx_credentials.dart';
import 'httpx_push_stream.dart';
import 'httpx_request.dart';
import 'httpx_typedefs.dart';

abstract class HttpxClient {
  factory HttpxClient() => HttpxClientImpl();

  HttpxLogCallback? get logCallback;
  set logCallback(HttpxLogCallback? callback);

  BadCertificateCallback? get badCertificateCallback;
  set badCertificateCallback(BadCertificateCallback? callback);

  SecureConnectionTestCallback get secureConnectionTestCallback;
  set secureConnectionTestCallback(SecureConnectionTestCallback callback);

  SecurityContext? get securityContext;
  set securityContext(SecurityContext? securityContext);

  String? get defaultUserAgent;
  set defaultUserAgent(String? defaultUserAgent);

  int get defaultMaxRedirects;
  set defaultMaxRedirects(int defaultMaxRedirects);

  HttpxHeaders get defaultHeaders;
  set defaultHeaders(HttpxHeaders defaultHeaders);

  http2.ClientSettings get http2ClientSettings;
  set http2ClientSettings(http2.ClientSettings http2ClientSettings);

  Duration get connectionIdleTimeout;
  set connectionIdleTimeout(Duration connectionIdleTimeout);

  bool get persistantConnection;
  set persistantConnection(bool persistantConnection);

  HttpxCachePolicy get defaultCachePolicy;
  set defaultCachePolicy(HttpxCachePolicy defaultCachePolicy);

  List<HttpxCacheStore> get cacheStores;

  HttpxRequest createRequest({
    required String method,
    required Uri uri,
    HttpxHeaders? headers,
    HttpxCachePolicy? cachePolicy,
    int? maxRedirects,
    Duration? connectionTimeout,
    Iterable<HttpxCredentials>? realmsCredentials,
  });

  Future<HttpxPushStream> createPushStream({
    required Uri uri,
    required String method,
    HttpxHeaders? headers,
    int? maxRedirects,
    Duration? connectionTimeout,
    Iterable<HttpxCredentials>? realmsCredentials,
  });
}
