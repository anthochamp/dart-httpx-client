// SPDX-FileCopyrightText: © 2023 - 2024 Anthony Champagne <dev@anthonychampagne.fr>
//
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';
import 'dart:io';

import 'package:mutex/mutex.dart';

import '../httpx_typedefs.dart';

class _PendingSocket {
  final String host;
  final Socket socket;
  final void Function(_PendingSocket) onIdleTimeout;

  _PendingSocket({
    required this.host,
    required this.socket,
    required this.onIdleTimeout,
  });

  final DateTime _createdAt = DateTime.now();
  Timer? _timer;

  int get port => socket.remotePort;

  bool get secure => socket is SecureSocket;

  void resetIdleTimeoutTimer(Duration? idleTimeout) {
    _timer?.cancel();
    _timer = null;

    if (idleTimeout != null) {
      final timerTimeout = DateTime.now().difference(_createdAt) - idleTimeout;

      // Do NOT call callback in sync, it may cause a race condition if idleTimeout is low enough
      _timer = Timer(
        timerTimeout.isNegative ? Duration.zero : timerTimeout,
        () => onIdleTimeout(this),
      );
    }
  }
}

class _ConnectionTask implements ConnectionTask<Socket> {
  @override
  final Future<Socket> socket;

  _ConnectionTask(Future<Socket> socketFuture) : socket = socketFuture;

  @override
  // ignore: no-empty-block
  void cancel() {
    // does nothing
  }
}

class HttpxBuiltinHttpConnections {
  static const alpnProtocols = ['http/1.0', 'http/1.1'];

  final HttpxSocketConnectCallback socketConnectCallback;

  HttpxBuiltinHttpConnections({
    required this.secureConnectionTestCallback,
    required this.pendingSocketIdleTimeout,
    required this.socketConnectCallback,
  });

  final _pendingSockets = <_PendingSocket>[];
  final _pendingSocketsMutex = Mutex();

  HttpxLogCallback? logCallback;

  SecureConnectionTestCallback secureConnectionTestCallback;

  Duration pendingSocketIdleTimeout;

  Future<ConnectionTask<Socket>> connectionFactoryCallback(
    Uri uri,
    String? proxyHost,
    int? proxyPort,
  ) async {
    if (proxyHost != null || proxyPort != null) {
      // TODO: https://pub.dev/packages/socks5_proxy
      throw UnsupportedError('Proxy are not supported');
    }

    final secure = secureConnectionTestCallback(uri.scheme);

    // ignore: close_sinks
    final socket = await _popPendingSocket(uri.host, uri.port, secure);

    if (socket == null) {
      return socketConnectCallback(
        host: uri.host,
        port: uri.port,
        secure: secure,
        alpnProtocols: alpnProtocols,
      );
    } else {
      return _ConnectionTask(Future.value(socket));
    }
  }

  Future<void> addPendingSocket(Socket socket, {required String host}) =>
      _pendingSocketsMutex.protect<void>(() {
        final pendingSocket = _PendingSocket(
          host: host,
          socket: socket,
          onIdleTimeout: _onPendingSocketIdleTimeout,
        );

        _pendingSockets.add(pendingSocket);

        pendingSocket.resetIdleTimeoutTimer(pendingSocketIdleTimeout);

        return Future.value();
      });

  void _onPendingSocketIdleTimeout(_PendingSocket pendingSocket) {
    _pendingSocketsMutex.protect<void>(() {
      _pendingSockets.remove(pendingSocket);

      return Future.value();
    });
  }

  Future<Socket?> _popPendingSocket(String host, int port, bool secure) =>
      _pendingSocketsMutex.protect<Socket?>(() async {
        final index = _pendingSockets.indexWhere(
          (element) =>
              element.host == host &&
              element.port == port &&
              element.secure == secure,
        );

        if (index == -1) {
          return null;
        }

        final pendingSocket = _pendingSockets.elementAt(index);

        _pendingSockets.removeAt(index);

        return pendingSocket.socket;
      });
}
