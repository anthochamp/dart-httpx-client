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
