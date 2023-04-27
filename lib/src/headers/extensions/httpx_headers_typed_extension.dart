// Copyright 2023, Anthony Champagne. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:http_parser/http_parser.dart';

import '../httpx_headers.dart';
import '../httpx_headers_typedefs.dart';

extension HttpxHeadersTypedExtension on HttpxHeaders {
  void setDateTimeField(HttpxHeaderName name, DateTime? value) =>
      this[name] = value == null ? null : [formatHttpDate(value)];
  DateTime? getDateTimeField(HttpxHeaderName name) {
    final value = this[name]?.single;

    return value == null ? null : parseHttpDate(value);
  }

  void setIntField(HttpxHeaderName name, int? value) =>
      this[name] = value == null ? null : [value.toString()];
  int? getIntField(HttpxHeaderName name) {
    final value = this[name]?.single;

    return value == null ? null : int.parse(value);
  }

  Duration? getDurationInSecondsField(HttpxHeaderName name) {
    final value = getIntField(name);

    return value == null ? null : Duration(seconds: value);
  }
}
