// SPDX-FileCopyrightText: © 2023 - 2024 Anthony Champagne <dev@anthonychampagne.fr>
//
// SPDX-License-Identifier: BSD-3-Clause

import 'package:freezed_annotation/freezed_annotation.dart';

part 'httpx_credentials.freezed.dart';

@freezed
class HttpxCredentials with _$HttpxCredentials {
  // https://www.rfc-editor.org/rfc/rfc7617
  const factory HttpxCredentials.basic({
    required String realm,
    required String username,
    required String password,
    @Default(false) bool proxyCredentials,
  }) = HttpxCredentialsBasic;

  // https://www.rfc-editor.org/rfc/rfc7616
  /*
  const factory HttpxCredentials.digest({
    String? realm,

  }) = HttpxCredentialsDigest;
  */

  // https://www.rfc-editor.org/rfc/rfc6750
  const factory HttpxCredentials.bearer({
    String? realm,
    required String accessToken,
    @Default(false) bool proxyCredentials,
  }) = HttpxCredentialsBearer;

  /*
  // https://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-http-mac-05
  const factory HttpxCredentials.mac({
    String? realm,

  }) = HttpxCredentialsMac;
  */

  /*
  // https://github.com/mozilla/hawk/blob/main/API.md
  const factory HttpxCredentials.hawk({
    String? realm,

  }) = HttpxCredentialsHawk;
  */

  /*
  factory HttpxCredentials.fromWwwAuthorizationHeader({

  }) {}
  */

  factory HttpxCredentials.fromOAuth2({
    String? realm,
    required String tokenType,
    required String accessToken,
    bool proxyCredentials = false,
  }) {
    switch (tokenType) {
      case 'bearer':
        return HttpxCredentials.bearer(
          realm: realm,
          accessToken: accessToken,
          proxyCredentials: proxyCredentials,
        );

      case 'mac':
      default:
        throw UnsupportedError(
          'OAuth2 token type "$tokenType" is not supported',
        );
    }
  }
}
