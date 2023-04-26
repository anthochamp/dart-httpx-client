import 'dart:async';

import 'package:httpx_client/src/headers/httpx_headers.dart';
import 'package:httpx_client/src/httpx_redirect_info.dart';

abstract class HttpxResponse implements Stream<List<int>> {
  DateTime get firstByteReceivedTime;

  Iterable<HttpxRedirectInfo> get redirects;

  int get status;

  String? get statusText;

  HttpxHeaders get headers;

  // must be called if no stream subscription is done
  FutureOr<void> dispose();
}
