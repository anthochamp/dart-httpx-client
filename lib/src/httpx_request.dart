import 'dart:async';

import 'package:httpx_client/src/headers/httpx_headers.dart';
import 'package:httpx_client/src/httpx_response.dart';

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
