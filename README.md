# Yet Another HTTP client

HTTP1/2 client in the style of Dart's HttpClient with an integrated RFC-compliant private cache.

This package exists to support the [ac_fetch](https://pub.dev/packages/ac_fetch) package. You might want to check it, it allows easier data management.

## Features

What it implements:

- HTTP/1 client using [dart:io's HttpClient](https://api.dart.dev/dart-io/HttpClient-class.html);
- HTTP/2 client using [http2 package](https://pub.dev/packages/http2) with automatic fallback to HTTP/1 without severing the TCP connection;
- HTTP headers (parsing, folding, sensitive-data-aware formatting, etc.);
- HTTP credentials;
- [RFC-7231](https://datatracker.ietf.org/doc/html/rfc7231) and [RFC-5861](https://datatracker.ietf.org/doc/html/rfc5861) compliant HTTP private cache (with limitations, see below).

What it does NOT implement yet:

- HTTP/2 request automatic redirection;
- `Digest`, `MAC` and `Hawk` authentication schemes;
- HTTP/2 Push Streams;
- [Unsecure HTTP/1.1 connection upgrade to HTTP/2](https://www.rfc-editor.org/rfc/rfc7540#section-3.2);
- [HTTP/2 connection over TCP with prior knowledge](https://www.rfc-editor.org/rfc/rfc7540#section-3.4);

HTTP cache limitations:

- [Content negociation fields](https://www.rfc-editor.org/rfc/rfc9110.html#name-content-negotiation-fields) are not supported for cache entry selection of Vary-ing response (meaning that if multiple cached entries are available for a given resource, cache will make a conditional request to the server to disambiguate which one should be returned),
- Caching of responses with [partial content](https://datatracker.ietf.org/doc/html/rfc7233#section-4.1) is not supported.
- Caching of [POST](https://datatracker.ietf.org/doc/html/rfc7231#section-4.3.3) responses is disabled.

## Usage

### Simple request

```dart
const client = HttpxClient();

final request = client.createRequest(
    method: 'POST',
    uri: Uri.parse('https://www.example.com'),
    headers: HttpxHeaders.fromMap({
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
    }),
);

await request.write('{"data": "hello world!"}'.codeUnits);

final response = await request.dispose();

final data = await response.fold(<int>[], (previous, element) => previous..addAll(element));

await response.dispose();

print(data);
```

### Cache store

```dart
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:hive/hive.dart';

final supportDir =
    await path_provider.getApplicationSupportDirectory();

// Always use an encrypted store for protecting your user data !
// (and use appropriate means to protect its key)
final encryptionCipher =
    HiveAesCipher('01234567890123456789012345678901'.codeUnits);

HttpxCacheHiveStore store = HttpxCacheHiveStore(
    boxPath: supportDir.path,
    encryptionCipher: encryptionCipher,
);

try {
    await store.open();
} catch (_) {
    // if the store fail to open, delete it from disk
    await Hive.deleteBoxFromDisk(
      HttpxCacheHiveStore.defaultBoxName,
      path: supportDir.path,
    );

    // and try to re-open
    await store.open();
}

final client = HttpxClient();

client.cacheStores.add(store);

// do request...

```

### Cache Policy

When making a request, you can policy the cache to act in a different way that it is supposed to using the `cachePolicy` property argument of the `HttpxClient.createRequest` method.

```dart
const client = HttpxClient();
final request = client.createRequest(
    method: 'GET',
    uri: Uri.parse('https://www.example.com'),
    cachePolicy: HttpxCachePolicy.standard,
);
```

#### Policies

| CachePolicy | Description |
|---|---|
| `standard` (default) | Standard behaviour. |
| `straightToNetwork` | Behaves as if there is no HTTP cache for the request. It will still update the cache with the response. |
| `ignoreDirectives` | Uses any response in the HTTP cache matching the request, not paying attention to `Pragma` / `Cache Control` directives in both the request and the cached response(s). |
| `staleWhileRevalidate` | Enable [stale-while-revalidate](https://datatracker.ietf.org/doc/html/rfc5861#section-3) even for cached responses which do not have the directive (or if it's past its lifetime). It does not bypass `Pragma` / `Cache-Control` directives (`no-cache` and/or `min-fresh` directives may prevent revalidation in background). |

#### Cache directives

You can also control the cache using the `Pragma` / `Cache-Control` directives in the request :
- [Force revalidation (MDN)](https://developer.mozilla.org/en-US/docs/Web/HTTP/Caching#force_revalidation)
- [Don't cache response (MDN)](https://developer.mozilla.org/en-US/docs/Web/HTTP/Caching#dont_cache)
- [Provide up-to-date content everytime (MDN)](https://developer.mozilla.org/en-US/docs/Web/HTTP/Caching#provide_up-to-date_content_every_time)

