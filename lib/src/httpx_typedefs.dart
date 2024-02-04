// SPDX-FileCopyrightText: © 2023 - 2024 Anthony Champagne <dev@anthonychampagne.fr>
//
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';

import 'headers/httpx_headers.dart';
import 'httpx_request.dart';

typedef SecureConnectionTestCallback = bool Function(String uriScheme);

typedef HttpxLogCallback = void Function(Object?);

typedef HttpxSocketConnectCallback = Future<ConnectionTask<Socket>> Function({
  required String host,
  required int port,
  required bool secure,

  /// https://www.iana.org/assignments/tls-extensiontype-values/tls-extensiontype-values.xhtml#alpn-protocol-ids
  List<String>? alpnProtocols,
});

typedef HttpxCreateNetworkRequestCallback = Future<HttpxRequest> Function({
  required String method,
  required Uri uri,
  required HttpxHeaders headers,
  required int maxRedirects,
  required Duration? connectionTimeout,
});
