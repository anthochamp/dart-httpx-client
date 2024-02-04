// SPDX-FileCopyrightText: © 2023 - 2024 Anthony Champagne <dev@anthonychampagne.fr>
//
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';

import '../../headers/httpx_headers_typedefs.dart';
import 'httpx_cache_store_entry.dart';

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
