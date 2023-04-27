// Copyright 2023, Anthony Champagne. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'headers/httpx_headers.dart';
import 'httpx_redirect_info.dart';

abstract class HttpxResponse implements Stream<List<int>> {
  DateTime get firstByteReceivedTime;

  Iterable<HttpxRedirectInfo> get redirects;

  int get status;

  String? get statusText;

  HttpxHeaders get headers;

  // must be called if no stream subscription is done
  FutureOr<void> dispose();
}
