import 'package:http_parser/http_parser.dart';

import 'package:httpx_client/src/headers/httpx_headers.dart';
import 'package:httpx_client/src/headers/httpx_headers_typedefs.dart';

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
