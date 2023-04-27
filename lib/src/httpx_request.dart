// Copyright 2023, Anthony Champagne. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
