import 'package:httpx_client/src/cache/httpx_cache_policy.dart';
import 'package:httpx_client/src/cache/store/httpx_cache_store.dart';
import 'package:httpx_client/src/headers/httpx_headers.dart';
import 'package:httpx_client/src/httpx_request.dart';
import 'package:httpx_client/src/httpx_response.dart';

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
