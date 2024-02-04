// SPDX-FileCopyrightText: © 2023 - 2024 Anthony Champagne <dev@anthonychampagne.fr>
//
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';

import 'headers/httpx_headers.dart';
import 'httpx_response.dart';

abstract class HttpxRequest {
  int get maxRedirects;

  String get method;

  Uri get uri;

  HttpxHeaders get headers;

  int get dataSent;

  bool get closed;

  DateTime? get firstByteSentTime;

  FutureOr<void> write(List<int> encodedData);

  FutureOr<void> flush();

  FutureOr<HttpxResponse> close([Duration? timeout]);
}
