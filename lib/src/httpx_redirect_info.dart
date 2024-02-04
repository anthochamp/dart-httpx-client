// SPDX-FileCopyrightText: © 2023 - 2024 Anthony Champagne <dev@anthonychampagne.fr>
//
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';

class HttpxRedirectInfo implements RedirectInfo {
  @override
  final int statusCode;
  @override
  final String method;
  @override
  final Uri location;

  HttpxRedirectInfo({
    required this.statusCode,
    required this.method,
    required this.location,
  });

  factory HttpxRedirectInfo.from(RedirectInfo redirectInfo) =>
      HttpxRedirectInfo(
        location: redirectInfo.location,
        method: redirectInfo.method,
        statusCode: redirectInfo.statusCode,
      );
}
