import 'dart:io';

import 'package:httpx_client/src/headers/httpx_headers.dart';
import 'package:httpx_client/src/headers/httpx_headers_typedefs.dart';
import 'package:httpx_client/src/headers/httpx_headers_value_parser.dart';

class HttpxViaIntermediate {
  final String? protocolName;
  final String protocolVersion;
  final String receivedBy;
  final int? port;
  final String? comment;

  HttpxViaIntermediate._({
    this.protocolName,
    required this.protocolVersion,
    required this.receivedBy,
    this.port,
    this.comment,
  });

  factory HttpxViaIntermediate.fromHeaderValue(HttpxHeaderValue value) {
    final parts = HttpxHeaderValueParser.splitByWs(value);

    final receivedProtocol = parts.first.split('/');
    final receivedBy = parts[1].split(':');

    return HttpxViaIntermediate._(
      protocolName:
          receivedProtocol.length == 1 ? null : receivedProtocol.first,
      protocolVersion: receivedProtocol.last,
      receivedBy: receivedBy.first,
      port: receivedBy.length == 1 ? null : int.parse(receivedBy.last),
      comment: HttpxHeaderValueParser.parseHttpComment(parts[2]),
    );
  }
}

extension HttpxHeadersViaExtension on HttpxHeaders {
  // https://httpwg.org/specs/rfc9110.html#field.via
  Iterable<HttpxViaIntermediate>? getVia() {
    return this[HttpHeaders.viaHeader]
        ?.map(HttpxViaIntermediate.fromHeaderValue);
  }
}
