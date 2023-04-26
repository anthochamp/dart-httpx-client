import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http2/http2.dart';
import 'package:mutex/mutex.dart';

import 'package:httpx_client/src/httpx_typedefs.dart';

class _Connection {
  final String host;
  final int port;
  final ClientTransportConnection transport;
  final void Function(_Connection) onIdleTimeout;

  _Connection({
    required this.host,
    required this.port,
    required this.transport,
    required this.onIdleTimeout,
  });

  Timer? _timer;

  bool isValid() => transport.isOpen;

  void startIdleTimeoutTimer(Duration? idleTimeout) {
    if (_timer == null && idleTimeout != null) {
      _timer = Timer(
        idleTimeout,
        () => onIdleTimeout(this),
      );
    }
  }

  void stopIdleTimeoutTimer() {
    _timer?.cancel();
    _timer = null;
  }
}

class HttpxHttp2Connections {
  static const alpnProtocols = ['h2'];

  HttpxHttp2Connections({
    required this.persistantConnection,
    required this.connectionIdleTimeout,
    required this.clientSettings,
  });

  final _connections = <_Connection>[];
  final _connectionsRwMutex = ReadWriteMutex();

  HttpxLogCallback? logCallback;
  ClientSettings clientSettings;
  bool persistantConnection;
  Duration connectionIdleTimeout;

  Future<ClientTransportConnection> add(
    Socket socket, {
    required String host,
    required int port,
  }) {
    final http2Transport = ClientTransportConnection.viaSocket(
      socket,
      settings: clientSettings,
    );

    http2Transport.onActiveStateChanged = (isActive) => _onActiveStateChanged(
          http2Transport,
          isActive,
        );

    return _connectionsRwMutex
        .protectWrite<ClientTransportConnection>(() async {
      final connection = _Connection(
        host: host,
        port: port,
        transport: http2Transport,
        onIdleTimeout: _onConnectionIdleTimeout,
      );

      connection.startIdleTimeoutTimer(connectionIdleTimeout);

      _connections.add(connection);

      return http2Transport;
    });
  }

  Future<ClientTransportConnection?> find(
    String host,
    int port,
  ) =>
      _connectionsRwMutex.protectRead<ClientTransportConnection?>(() async {
        return _connections
            .firstWhereOrNull(
              (element) =>
                  element.isValid() &&
                  element.host == host &&
                  element.port == port,
            )
            ?.transport;
      });

  void _onActiveStateChanged(
    ClientTransportConnection transport,
    bool isActive,
  ) async {
    final connection =
        await _connectionsRwMutex.protectRead<_Connection?>(() async {
      return _connections.firstWhereOrNull(
        (element) => element.transport == transport,
      );
    });

    if (connection != null) {
      if (!isActive) {
        logCallback?.call(
          'HTTP2 connection to ${connection.host}:${connection.port} is inactive, starting idle timer (timeout: ${persistantConnection ? connectionIdleTimeout : Duration.zero})',
        );

        connection.startIdleTimeoutTimer(
          persistantConnection ? connectionIdleTimeout : Duration.zero,
        );
      } else {
        logCallback?.call(
          'HTTP2 connection to ${connection.host}:${connection.port} is now active, stopping idle timer',
        );

        connection.stopIdleTimeoutTimer();
      }
    }
  }

  void _onConnectionIdleTimeout(_Connection connection) async {
    logCallback?.call(
      'Idling HTTP2 connection to ${connection.host}:${connection.port} timed-out, closing...',
    );

    await _connectionsRwMutex.protectWrite<void>(() {
      _connections
          .removeWhere((element) => element.transport == connection.transport);

      return Future.value();
    });

    await connection.transport.finish();

    logCallback?.call(
      'Idling HTTP2 connection to ${connection.host}:${connection.port} closed.',
    );
  }
}
