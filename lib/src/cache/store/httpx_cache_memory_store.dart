// SPDX-FileCopyrightText: © 2023 - 2024 Anthony Champagne <dev@anthonychampagne.fr>
//
// SPDX-License-Identifier: BSD-3-Clause

import '../../headers/httpx_headers_typedefs.dart';
import 'httpx_cache_store.dart';
import 'httpx_cache_store_entry.dart';

class HttpxCacheMemoryStore implements HttpxCacheStore {
  final bool backupOnly;

  /// response must includes status line, headers and body
  /// use "curl -i [url]"
  final Iterable<List<int>> Function(Uri uri)? onGetCurlData;

  HttpxCacheMemoryStore({
    this.backupOnly = false,
    this.onGetCurlData,
  });

  final _cache = <Uri, List<HttpxCacheStoreEntry>>{};

  @override
  Iterable<HttpxCacheStoreEntry> getAll(HttpxCacheStorePk primaryKey) {
    if (backupOnly) {
      return [];
    }

    var entries = _cache[primaryKey] ?? <HttpxCacheStoreEntry>[];

    /*
    if (entries.isEmpty && onGetCurlData != null) {
      final curlDataList = onGetCurlData!(primaryKey);

      // TODO: parse curl data

      // TODO: add to cache
    }
    */

    return entries.map((e) => e.clone());
  }

  @override
  void add(HttpxCacheStoreEntry entry) {
    final primaryKey = HttpxCacheStore.composePrimaryKey(entry.uri);

    _cache[primaryKey] = _cache[primaryKey] ?? [];
    _cache[primaryKey]!.add(entry.clone());
  }

  @override
  void removeWhere({
    required HttpxCacheStorePk primaryKey,
    HttpxHeadersEntries? requestHeadersFilter,
    HttpxHeadersEntries? responseHeadersFilter,
  }) {
    _cache[primaryKey]?.removeWhere((cacheEntry) {
      if (requestHeadersFilter != null &&
          !cacheEntry.requestHeaders.matchAll(requestHeadersFilter)) {
        return false;
      }

      if (responseHeadersFilter != null &&
          !cacheEntry.responseHeaders.matchAll(responseHeadersFilter)) {
        return false;
      }

      return true;
    });
  }
}
