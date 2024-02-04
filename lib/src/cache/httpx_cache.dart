// SPDX-FileCopyrightText: © 2023 - 2024 Anthony Champagne <dev@anthonychampagne.fr>
//
// SPDX-License-Identifier: BSD-3-Clause

import '../headers/httpx_headers.dart';
import '../httpx_request.dart';
import '../httpx_response.dart';
import 'httpx_cache_policy.dart';
import 'store/httpx_cache_store.dart';

abstract class HttpxCache {
  List<int> get cacheableStatusCode;
  List<String> get cacheableHttpMethods;

  List<HttpxCacheStore> get stores;

  Future<void> update({
    required String method,
    required Uri uri,
    required HttpxHeaders requestHeaders,
    required DateTime firstByteSentTime,
    required HttpxResponse response,
    required List<int> responseBody,
  });

  Future<HttpxResponse?> process({
    required HttpxRequest request,
    required HttpxCachePolicy cachePolicy,
    required Duration? timeout,
    required Duration? connectionTimeout,
  });
}
