// SPDX-FileCopyrightText: © 2023 - 2024 Anthony Champagne <dev@anthonychampagne.fr>
//
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';
import 'dart:io';

import 'package:http2/http2.dart';

import '../headers/httpx_headers.dart';
import '../httpx_redirect_info.dart';
import '../httpx_response.dart';
import '../httpx_typedefs.dart';
import 'httpx_http2_utilities.dart';

class HttpxHttp2Response extends Stream<List<int>> implements HttpxResponse {
  @override
  final Iterable<HttpxRedirectInfo> redirects;

  final String method;
  final Uri uri;
  final HttpxLogCallback? logCallback;

  HttpxHttp2Response(
    this._transportStream, {
    required this.method,
    required this.uri,
    required this.redirects,
    required this.logCallback,
  }) {
    _transportStream.incomingMessages.listen(
      _onIncomingMessage,
      onError: _dataStreamController.addError,
      onDone: () {
        unawaited(_dataStreamController.close());

        logCallback?.call(
          '[$method $uri] HTTP2 response reception completed.',
        );
      },
      cancelOnError: false,
    );
  }

  final ClientTransportStream _transportStream;
  final _streamController = StreamController<List<int>>();
  final _readyCompleter = Completer<void>();
  final _headers = HttpxHeaders();
  final _dataStreamController = StreamController<List<int>>();
  DateTime? _firstByteReceivedTime;
  int? _status;

  Future<void> get readyFuture => _readyCompleter.future;

  @override
  DateTime get firstByteReceivedTime => _firstByteReceivedTime!;

  @override
  HttpxHeaders get headers => _headers;

  @override
  int get status => _status!;

  @override
  String? get statusText => null;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
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
  Future<void> dispose() async {
    await _streamController.close();
  }

  void _onIncomingMessage(StreamMessage message) {
    _firstByteReceivedTime ??= DateTime.now();

    if (message is HeadersStreamMessage) {
      final decodedHeaders = HttpxHttp2Utilities.http2HeadersDecode(message);

      String? status = decodedHeaders.remove(':status');

      if (status != null) {
        logCallback?.call(
          '[$method $uri] Received status: $status',
        );

        _status = int.tryParse(status);
      }

      for (final entry in decodedHeaders.entries) {
        _headers.add(entry.key, entry.value);
      }

      logCallback?.call(
        '[$method $uri] Headers updated: $_headers',
      );

      if (_status == null) {
        _readyCompleter.completeError(Exception(
          'HTTP2 headers message did not contain :status field (or invalid)',
        ));
      } else {
        _readyCompleter.complete();
      }

      final contentEncodingList =
          headers[HttpHeaders.contentEncodingHeader] ?? [];

      Stream<List<int>> dataStream = _dataStreamController.stream;

      for (final contentEncoding in contentEncodingList) {
        switch (contentEncoding.toLowerCase()) {
          case 'gzip':
            dataStream = dataStream.transform(GZipCodec().decoder);
            break;

          default:
            _streamController.addError(Exception(
              'Content encoding "$contentEncoding" is not supported',
            ));
            break;
        }
      }

      _streamController.addStream(dataStream).then((_) {
        if (contentEncodingList.isNotEmpty) {
          logCallback?.call(
            '[$method $uri] HTTP2 response decoding completed.',
          );
        }

        unawaited(_streamController.close());
      });
    } else if (message is DataStreamMessage) {
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.completeError(Exception(
          'HTTP2 data message received before headers',
        ));
      }

      logCallback?.call(
        '[$method $uri] Received data message (${message.bytes.length} bytes)',
      );

      _dataStreamController.add(message.bytes);
    }
  }
}
