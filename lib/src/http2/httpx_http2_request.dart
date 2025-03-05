// SPDX-FileCopyrightText: © 2023 - 2024 Anthony Champagne <dev@anthonychampagne.fr>
//
// SPDX-License-Identifier: BSD-3-Clause

import 'package:ac_dart_essentials/ac_dart_essentials.dart';
import 'package:http2/http2.dart';

import '../headers/httpx_headers.dart';
import '../httpx_redirect_info.dart';
import '../httpx_request.dart';
import '../httpx_response.dart';
import '../httpx_typedefs.dart';
import 'httpx_http2_response.dart';
import 'httpx_http2_utilities.dart';

class HttpxHttp2Request implements HttpxRequest {
  @override
  final String method;

  @override
  final Uri uri;

  @override
  final HttpxHeaders headers;

  @override
  final int maxRedirects;

  final HttpxLogCallback? logCallback;

  HttpxHttp2Request(
    this._transport, {
    required this.method,
    required this.uri,
    required this.headers,
    required this.maxRedirects,
    required this.logCallback,
  });

  final ClientTransportConnection _transport;
  final _openMemoizer = Memoizer<ClientTransportStream>();
  DateTime? _firstByteSentTime;
  int _dataSent = 0;

  @override
  bool closed = false;

  @override
  int get dataSent => _dataSent;

  @override
  DateTime? get firstByteSentTime => _firstByteSentTime;

  @override
  void write(List<int> encodedData) {
    final transportStream = _open();

    logCallback?.call(
      '[$method $uri] Sending ${encodedData.length} bytes of data...',
    );

    transportStream.sendData(encodedData);

    _dataSent += encodedData.length;

    logCallback?.call(
      '[$method $uri] ${encodedData.length} bytes of data sent',
    );
    //logCallback?.call(const AsciiDecoder(allowInvalid: true).convert(encodedData).inspect());
  }

  @override
  // ignore: no-empty-block
  void flush() {
    // does nothing
  }

  @override
  Future<HttpxResponse> close([Duration? timeout]) async {
    final transportStream = _open();

    logCallback?.call('[$method $uri] Closing request...');

    await transportStream.outgoingMessages.close();

    logCallback?.call('[$method $uri] Request closed.');

    closed = true;

    final redirects = <HttpxRedirectInfo>[];

    HttpxHttp2Response response;

    Uri lastUri = uri;

    do {
      response = HttpxHttp2Response(
        transportStream,
        method: method,
        uri: lastUri,
        redirects: redirects,
        logCallback: logCallback,
      );

      var readyFuture = response.readyFuture;

      if (timeout != null) {
        readyFuture = readyFuture.timeout(timeout);
      }

      await readyFuture;

      // TODO: handle redirects
      // TODO: https://developer.mozilla.org/en-US/docs/Web/HTTP/Redirections
    } while (false);

    return response;
  }

  ClientTransportStream _open() => _openMemoizer.runOnce(() {
    logCallback?.call('[$method $uri] Opening request...');

    final transportStream = _transport.makeRequest(
      HttpxHttp2Utilities.http2HeadersEncode(
        method: method,
        uri: uri,
        headers: headers,
      ),
    );

    _firstByteSentTime = DateTime.now();
    headers.lock();

    logCallback?.call('[$method $uri] Request opened.');

    return transportStream;
  });
}
