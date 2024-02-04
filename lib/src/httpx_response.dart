// SPDX-FileCopyrightText: © 2023 - 2024 Anthony Champagne <dev@anthonychampagne.fr>
//
// SPDX-License-Identifier: BSD-3-Clause

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
