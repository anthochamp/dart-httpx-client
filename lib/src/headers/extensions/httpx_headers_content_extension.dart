// Copyright 2023, Anthony Champagne. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import '../httpx_headers.dart';
import 'httpx_headers_typed_extension.dart';

extension HttpxHeadersContentExtension on HttpxHeaders {
  ContentType? getContentType() {
    final value = this[HttpHeaders.contentTypeHeader]?.single;

    return value == null ? null : ContentType.parse(value);
  }

  Encoding? getCharsetEncoding() {
    final charset = getContentType()?.charset;
    if (charset == null) {
      return null;
    }

    final encoding = Encoding.getByName(charset);
    if (encoding == null) {
      throw UnsupportedError('Charset "$charset" is not supported');
    }

    return encoding;
  }

  int? getContentLength() => getIntField(HttpHeaders.contentLengthHeader);
  void setContentLength(int? contentLength) =>
      setIntField(HttpHeaders.contentLengthHeader, contentLength);
}
