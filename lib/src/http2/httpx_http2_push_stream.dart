// Copyright 2023, Anthony Champagne. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:ac_dart_essentials/ac_dart_essentials.dart';
import 'package:http2/http2.dart';

import '../headers/httpx_headers.dart';
import '../httpx_push_stream.dart';
import 'httpx_http2_utilities.dart';

class HttpxHttp2PushMessage implements HttpxPushMessage {
  HttpxHttp2PushMessage(this._http2TransportStreamPush);

  final TransportStreamPush _http2TransportStreamPush;
}

class HttpxHttp2PushStream extends Stream<HttpxPushMessage>
    implements HttpxPushStream {
  final int maxRedirects;
  final String method;
  final Uri uri;
  final HttpxHeaders headers;

  HttpxHttp2PushStream(
    this._transport, {
    required this.method,
    required this.uri,
    required this.headers,
    required this.maxRedirects,
  });

  final ClientTransportConnection _transport;
  // ignore: close_sinks
  final _streamController = StreamController<HttpxPushMessage>.broadcast();
  final _openMemoizer = Memoizer<ClientTransportStream>();

  @override
  StreamSubscription<HttpxPushMessage> listen(
    void Function(HttpxPushMessage event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      _streamController.stream.listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );

  @override
  void open() => _openMemoizer.runOnce(() {
        final transportStream = _transport.makeRequest(
          HttpxHttp2Utilities.http2HeadersEncode(
            method: method,
            uri: uri,
            headers: headers,
          ),
          endStream: true,
        );

        /*
        transportStream.peerPushes.listen(
          (push) => _streamController.add(HttpxHttp2PushMessage(push)),
        );
        */

        return transportStream;
      });

  @override
  void close() {
    _openMemoizer.value.terminate();

    // + cancel peerPushes subscription
  }
}
