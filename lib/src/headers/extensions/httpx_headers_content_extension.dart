import 'dart:convert';
import 'dart:io';

import 'package:httpx_client/src/headers/extensions/httpx_headers_typed_extension.dart';
import 'package:httpx_client/src/headers/httpx_headers.dart';

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
