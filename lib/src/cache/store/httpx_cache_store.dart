// Copyright 2023, Anthony Champagne. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
