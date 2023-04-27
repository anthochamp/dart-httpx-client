// Copyright 2023, Anthony Champagne. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../../headers/httpx_headers_typedefs.dart';
import 'httpx_cache_store.dart';
import 'httpx_cache_store_entry.dart';

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
