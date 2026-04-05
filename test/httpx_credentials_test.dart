// SPDX-FileCopyrightText: © 2023 - 2026 Anthony Champagne <dev@anthonychampagne.fr>
//
// SPDX-License-Identifier: BSD-3-Clause

import 'package:test/test.dart';

import 'package:ac_httpx_client/src/httpx_credentials.dart';

void main() {
  group('HttpxCredentials.fromOAuth2', () {
    test('bearer token type creates HttpxCredentialsBearer', () {
      final credentials = HttpxCredentials.fromOAuth2(
        tokenType: 'bearer',
        accessToken: 'my-access-token',
      );
      expect(credentials, isA<HttpxCredentialsBearer>());
      final bearer = credentials as HttpxCredentialsBearer;
      expect(bearer.accessToken, equals('my-access-token'));
      expect(bearer.proxyCredentials, isFalse);
      expect(bearer.realm, isNull);
    });

    test('bearer with realm and proxyCredentials', () {
      final credentials = HttpxCredentials.fromOAuth2(
        realm: 'example.com',
        tokenType: 'bearer',
        accessToken: 'tok',
        proxyCredentials: true,
      );
      final bearer = credentials as HttpxCredentialsBearer;
      expect(bearer.realm, equals('example.com'));
      expect(bearer.proxyCredentials, isTrue);
    });

    test('mac token type throws UnsupportedError', () {
      expect(
        () => HttpxCredentials.fromOAuth2(tokenType: 'mac', accessToken: 'tok'),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('unknown token type throws UnsupportedError', () {
      expect(
        () => HttpxCredentials.fromOAuth2(
          tokenType: 'unknown-type',
          accessToken: 'tok',
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  group('HttpxCredentials.basic', () {
    test('creates HttpxCredentialsBasic with required fields', () {
      const credentials = HttpxCredentials.basic(
        realm: 'my-realm',
        username: 'user',
        password: 'pass',
      );
      expect(credentials, isA<HttpxCredentialsBasic>());
      const basic = credentials as HttpxCredentialsBasic;
      expect(basic.realm, equals('my-realm'));
      expect(basic.username, equals('user'));
      expect(basic.password, equals('pass'));
      expect(basic.proxyCredentials, isFalse);
    });

    test('proxyCredentials defaults to false', () {
      const credentials = HttpxCredentials.basic(
        realm: 'r',
        username: 'u',
        password: 'p',
      );
      expect(credentials.proxyCredentials, isFalse);
    });

    test('proxyCredentials can be set to true', () {
      const credentials = HttpxCredentials.basic(
        realm: 'r',
        username: 'u',
        password: 'p',
        proxyCredentials: true,
      );
      expect(credentials.proxyCredentials, isTrue);
    });
  });

  group('HttpxCredentials.bearer', () {
    test('creates HttpxCredentialsBearer with accessToken', () {
      const bearer =
          HttpxCredentials.bearer(accessToken: 'tok') as HttpxCredentialsBearer;
      expect(bearer.accessToken, equals('tok'));
      expect(bearer.realm, isNull);
      expect(bearer.proxyCredentials, isFalse);
    });
  });
}
