import 'dart:async';

import 'package:httpx_client/src/cache/store/httpx_cache_store.dart';
import 'package:httpx_client/src/cache/store/httpx_cache_store_entry.dart';
import 'package:httpx_client/src/headers/httpx_headers_typedefs.dart';

class HttpxCacheStoreCombined implements HttpxCacheStore {
  final stores = <HttpxCacheStore>[];

  @override
  Future<Iterable<HttpxCacheStoreEntry>> getAll(
    HttpxCacheStorePk primaryKey,
  ) async {
    for (final store in stores) {
      final entries = await store.getAll(primaryKey);
      if (entries.isNotEmpty) {
        return entries;
      }
    }

    return [];
  }

  @override
  Future<void> add(HttpxCacheStoreEntry entry) =>
      Future.wait(stores.map((e) async => await e.add(entry)));

  @override
  Future<void> removeWhere({
    required HttpxCacheStorePk primaryKey,
    HttpxHeadersEntries? requestHeadersFilter,
    HttpxHeadersEntries? responseHeadersFilter,
  }) =>
      Future.wait(stores.map(
        (e) async => await e.removeWhere(
          primaryKey: primaryKey,
          requestHeadersFilter: requestHeadersFilter,
          responseHeadersFilter: responseHeadersFilter,
        ),
      ));
}
