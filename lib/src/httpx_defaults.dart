import 'dart:io';

import 'package:http2/http2.dart' show ClientSettings;

import 'package:httpx_client/src/cache/httpx_cache_policy.dart';
import 'package:httpx_client/src/headers/httpx_headers.dart';

const kInitialDefaultMaxRedirects = 5;

const kInitialPersistantConnection = true;

const kInitialConnectionIdleTimeout = Duration(seconds: 30);

const kInitialHttp2ClientSettings = ClientSettings(
  allowServerPushes: false,
  concurrentStreamLimit: null,
  streamWindowSize: null,
);

final kInitialDefaultHeaders = HttpxHeaders.fromMap({
  HttpHeaders.acceptEncodingHeader: 'gzip',
});

const kInitialDefaultCachePolicy = HttpxCachePolicy.standard;

const kKnownSecureConnectionUriSchemes = ['ipps'];

bool initialSecureConnectionTestCallback(String uriScheme) =>
    uriScheme.endsWith('https') ||
    kKnownSecureConnectionUriSchemes.contains(uriScheme);
