import 'dart:async';

import 'package:httpx_client/src/cache/store/httpx_cache_store_entry.dart';
import 'package:httpx_client/src/headers/httpx_headers_typedefs.dart';

typedef HttpxCacheStorePk = Uri;

abstract class HttpxCacheStore {
  static HttpxCacheStorePk composePrimaryKey(Uri uri) => uri.removeFragment();

  FutureOr<Iterable<HttpxCacheStoreEntry>> getAll(HttpxCacheStorePk primaryKey);

  FutureOr<void> add(HttpxCacheStoreEntry entry);

  FutureOr<void> removeWhere({
    required HttpxCacheStorePk primaryKey,
    HttpxHeadersEntries? requestHeadersFilter,
    HttpxHeadersEntries? responseHeadersFilter,
  });
}
