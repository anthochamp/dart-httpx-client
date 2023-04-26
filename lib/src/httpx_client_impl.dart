import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:anthochamp_dart_essentials/dart_essentials.dart';
import 'package:http2/http2.dart' as http2;

import 'package:httpx_client/src/builtin_http/httpx_builtin_http_connections.dart';
import 'package:httpx_client/src/builtin_http/httpx_builtin_http_request.dart';
import 'package:httpx_client/src/cache/httpx_cache_impl.dart';
import 'package:httpx_client/src/cache/httpx_cache_policy.dart';
import 'package:httpx_client/src/cache/store/httpx_cache_store.dart';
import 'package:httpx_client/src/headers/httpx_headers.dart';
import 'package:httpx_client/src/http2/httpx_http2_connections.dart';
import 'package:httpx_client/src/http2/httpx_http2_push_stream.dart';
import 'package:httpx_client/src/http2/httpx_http2_request.dart';
import 'package:httpx_client/src/httpx_client.dart';
import 'package:httpx_client/src/httpx_credentials.dart';
import 'package:httpx_client/src/httpx_defaults.dart';
import 'package:httpx_client/src/httpx_push_stream.dart';
import 'package:httpx_client/src/httpx_request.dart';
import 'package:httpx_client/src/httpx_request_impl.dart';
import 'package:httpx_client/src/httpx_typedefs.dart';

class HttpxClientImpl implements HttpxClient {
  HttpxClientImpl() {
    _cache = HttpxCacheImpl(
      createNetworkRequestCallback: _createNetworkRequest,
    );

    _builtinHttpConnections = HttpxBuiltinHttpConnections(
      secureConnectionTestCallback: initialSecureConnectionTestCallback,
      pendingSocketIdleTimeout: kInitialConnectionIdleTimeout,
      socketConnectCallback: _socketConnect,
    );

    _builtinHttpClient.connectionFactory =
        _builtinHttpConnections.connectionFactoryCallback;
    _builtinHttpClient.autoUncompress = true;
    _builtinHttpClient.idleTimeout = kInitialConnectionIdleTimeout;
    _builtinHttpClient.findProxy = (uri) => 'DIRECT';
    // HANDLED INTERNALLY:
    _builtinHttpClient.maxConnectionsPerHost = null;
    // HANDLED INTERNALLY:
    _builtinHttpClient.connectionTimeout = null;
  }

  late final HttpxCacheImpl _cache;
  late final HttpxBuiltinHttpConnections _builtinHttpConnections;
  final _builtinHttpClient = HttpClient(
    // HANDLED INTERNALLY:
    context: null,
  );
  final _http2Connections = HttpxHttp2Connections(
    clientSettings: kInitialHttp2ClientSettings,
    connectionIdleTimeout: kInitialConnectionIdleTimeout,
    persistantConnection: kInitialPersistantConnection,
  );
  final _knownEndpointAlpnProtocol = <String, String>{};

  @override
  HttpxCachePolicy defaultCachePolicy = kInitialDefaultCachePolicy;

  @override
  BadCertificateCallback? badCertificateCallback;

  @override
  SecurityContext? securityContext;

  @override
  int defaultMaxRedirects = kInitialDefaultMaxRedirects;

  @override
  HttpxHeaders defaultHeaders = kInitialDefaultHeaders;

  @override
  HttpxLogCallback? get logCallback => _cache.logCallback;
  @override
  set logCallback(HttpxLogCallback? logCallback) {
    _cache.logCallback = logCallback;
    _builtinHttpConnections.logCallback = logCallback;
    _http2Connections.logCallback = logCallback;
  }

  @override
  List<HttpxCacheStore> get cacheStores => _cache.stores;

  @override
  SecureConnectionTestCallback get secureConnectionTestCallback =>
      _builtinHttpConnections.secureConnectionTestCallback;
  @override
  set secureConnectionTestCallback(SecureConnectionTestCallback callback) =>
      _builtinHttpConnections.secureConnectionTestCallback = callback;

  @override
  bool get persistantConnection => _http2Connections.persistantConnection;
  @override
  set persistantConnection(bool persistantConnection) =>
      _http2Connections.persistantConnection = persistantConnection;

  @override
  http2.ClientSettings get http2ClientSettings =>
      _http2Connections.clientSettings;
  @override
  set http2ClientSettings(http2.ClientSettings settings) =>
      _http2Connections.clientSettings = settings;

  @override
  Duration get connectionIdleTimeout => _builtinHttpClient.idleTimeout;
  @override
  set connectionIdleTimeout(Duration connectionIdleTimeout) {
    _builtinHttpClient.idleTimeout = connectionIdleTimeout;
    _builtinHttpConnections.pendingSocketIdleTimeout = connectionIdleTimeout;
    _http2Connections.connectionIdleTimeout = connectionIdleTimeout;
  }

  @override
  String? get defaultUserAgent => _builtinHttpClient.userAgent;
  @override
  set defaultUserAgent(String? userAgent) =>
      _builtinHttpClient.userAgent = userAgent;

  @override
  HttpxRequest createRequest({
    required String method,
    required Uri uri,
    HttpxHeaders? headers,
    Iterable<HttpxCredentials>? realmsCredentials,
    int? maxRedirects,
    HttpxCachePolicy? cachePolicy,
    Duration? connectionTimeout,
  }) {
    logCallback?.call('$method request to $uri... ${{
      'headers': headers,
      'realmsCredentials': realmsCredentials != null,
      'maxRedirects': maxRedirects,
      'cachePolicy': cachePolicy,
      'connectionTimeout': connectionTimeout,
    }.inspect()}');

    return HttpxRequestImpl(
      method: method,
      uri: uri,
      headers: _prepareHeaders(
        headers: headers ?? defaultHeaders,
        uri: uri,
        realmsCredentials: realmsCredentials,
      ),
      maxRedirects: maxRedirects ?? defaultMaxRedirects,
      cachePolicy: cachePolicy ?? defaultCachePolicy,
      connectionTimeout: connectionTimeout,
      createNetworkRequestCallback: _createNetworkRequest,
      cache: WeakReference(_cache),
    );
  }

  @override
  Future<HttpxPushStream> createPushStream({
    required Uri uri,
    required String method,
    HttpxHeaders? headers,
    Iterable<HttpxCredentials>? realmsCredentials,
    int? maxRedirects,
    Duration? connectionTimeout,
  }) async {
    final http2Transport = await _getHttp2Transport(
      host: uri.host,
      port: uri.port,
      scheme: uri.scheme,
      connectionTimeout: connectionTimeout,
    );

    if (http2Transport == null) {
      throw Exception(
        'Failed to retrieve or create a HTTP2 connection to $uri',
      );
    }

    final preparedHeaders = _prepareHeaders(
      headers: headers ?? defaultHeaders,
      uri: uri,
      realmsCredentials: realmsCredentials,
    );

    return HttpxHttp2PushStream(
      http2Transport,
      method: method,
      uri: uri,
      headers: preparedHeaders,
      maxRedirects: maxRedirects ?? defaultMaxRedirects,
    );
  }

  String _composeHostPort(String host, int? port) {
    return host + (port == null ? '' : ':$port');
  }

  HttpxHeaders _prepareHeaders({
    required Uri uri,
    required HttpxHeaders headers,
    required Iterable<HttpxCredentials>? realmsCredentials,
  }) {
    final result = headers.clone();

    if (defaultUserAgent != null) {
      result.add(
        HttpHeaders.userAgentHeader,
        defaultUserAgent!,
        ifNotPresent: true,
      );
    }

    result.add(
      HttpHeaders.hostHeader,
      _composeHostPort(uri.host, uri.hasPort ? uri.port : null),
      ifNotPresent: true,
    );

    if (result.contains(HttpHeaders.rangeHeader)) {
      result.add(HttpHeaders.acceptEncodingHeader, 'identity');
    }

    if (realmsCredentials != null) {
      result.removeAll(HttpHeaders.proxyAuthorizationHeader);
      result.removeAll(HttpHeaders.authorizationHeader);

      for (final realmCredentials in realmsCredentials) {
        final authorizationHeaderName = realmCredentials.proxyCredentials
            ? HttpHeaders.proxyAuthorizationHeader
            : HttpHeaders.authorizationHeader;

        realmCredentials.when(
          basic: (realm, username, password, proxyCredentials) {
            result.add(
              authorizationHeaderName,
              HeaderValue(
                'Basic ${base64Encode(utf8.encode('$username:$password'))}',
                {
                  'realm': realm,
                  // 'charset': 'UTF-8' << per spec it is optional AND the only allowed value anyway
                },
              ).toString(),
            );
          },
          bearer: (realm, accessToken, proxyCredentials) {
            result.add(
              authorizationHeaderName,
              HeaderValue('Bearer $accessToken', {
                if (realm != null) 'realm': realm,
              }).toString(),
            );
          },
        );
      }
    }

    return result;
  }

  Future<http2.ClientTransportConnection?> _getHttp2Transport({
    required String scheme,
    required String host,
    required int port,
    Duration? connectionTimeout,
  }) async {
    final hostPort = _composeHostPort(host, port);

    if (_knownEndpointAlpnProtocol.containsKey(hostPort) &&
        _knownEndpointAlpnProtocol[hostPort] != 'h2') {
      return null;
    }

    var http2Transport = await _http2Connections.find(host, port);

    if (http2Transport == null) {
      if (secureConnectionTestCallback(scheme)) {
        final task = _socketConnect(
          host: host,
          port: port,
          secure: true,
          alpnProtocols: [
            ...HttpxBuiltinHttpConnections.alpnProtocols,
            ...HttpxHttp2Connections.alpnProtocols,
          ],
        );

        SecureSocket secureSocket;

        if (connectionTimeout == null) {
          secureSocket = await (await task).socket as SecureSocket;
        } else {
          secureSocket = await task.timeout(
            connectionTimeout,
            onTimeout: () => throw Exception(
              'Timed-out while trying to connect to "$host:$port" (unsecure)',
            ),
          ) as SecureSocket;
        }

        _knownEndpointAlpnProtocol[hostPort] =
            secureSocket.selectedProtocol ?? '';

        if (HttpxHttp2Connections.alpnProtocols
            .contains(secureSocket.selectedProtocol)) {
          http2Transport = await _http2Connections.add(
            secureSocket,
            host: host,
            port: port,
          );
        } else {
          await _builtinHttpConnections.addPendingSocket(
            secureSocket,
            host: host,
          );
        }
      } else {
        _knownEndpointAlpnProtocol[hostPort] = '';

        // might want to either upgrade a HTTP/1 unsecure connection or use HTTP2 over TCP
        // both case can be implemented here (second one needs a "forceHttp2OverCleartextTcp" option)
        // https://www.rfc-editor.org/rfc/rfc7540#section-3.2 (upgrade HTTP1 connection)
        // https://www.rfc-editor.org/rfc/rfc7540#section-3.4 (HTTP2 over TCP, with prior knowledge)
      }
    }

    return http2Transport;
  }

  Future<ConnectionTask<Socket>> _socketConnect({
    required String host,
    required int port,
    required bool secure,
    Iterable<String>? alpnProtocols,
  }) async {
    logCallback?.call('Connecting to $host:$port... ${{
      'secure': secure,
      'alpnProtocols': alpnProtocols,
    }.inspect()}');

    if (secure) {
      return SecureSocket.startConnect(
        host,
        port,
        supportedProtocols: alpnProtocols?.toList() ?? [],
        context: securityContext,
        onBadCertificate: (x509Certificate) =>
            badCertificateCallback?.call(x509Certificate, host, port) ?? false,
      );
    } else {
      return Socket.startConnect(host, port);
    }
  }

  Future<HttpxRequest> _createNetworkRequest({
    required String method,
    required Uri uri,
    required HttpxHeaders headers,
    required int maxRedirects,
    required Duration? connectionTimeout,
  }) async {
    logCallback?.call('$method network request to $uri... ${{
      'headers': headers,
      'maxRedirects': maxRedirects,
      'connectionTimeout': connectionTimeout,
    }.inspect()}');

    final http2Transport = await _getHttp2Transport(
      host: uri.host,
      port: uri.port,
      scheme: uri.scheme,
      connectionTimeout: connectionTimeout,
    );

    if (http2Transport == null) {
      return HttpxBuiltinHttpRequest(
        _builtinHttpClient,
        method: method,
        uri: uri,
        headers: headers,
        maxRedirects: maxRedirects,
        persistantConnection: persistantConnection,
        logCallback: logCallback,
      );
    } else {
      return HttpxHttp2Request(
        http2Transport,
        method: method,
        uri: uri,
        headers: headers,
        maxRedirects: maxRedirects,
        logCallback: logCallback,
      );
    }
  }
}
